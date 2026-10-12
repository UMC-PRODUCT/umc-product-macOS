// Created by euijjang97 on 10/13/26.
import { createPrivateKey, sign } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { setTimeout } from 'node:timers/promises';

const apiOrigin = 'https://api.appstoreconnect.apple.com';
const product = '91ef3566-24a7-42cd-acb6-d79ecf66f5e9';
const workflow = '3BCAECEC-BC31-4DD2-AA69-BC9BF0EB8645';

export function parseBranch(branch) {
    const match = /^prerelease\/(\d+\.\d+\.\d+)\/([1-9]\d*)$/.exec(branch);
    if (!match) throw new Error('Expected prerelease/<version>/<positive build number>');
    return { version: match[1], build: match[2] };
}

export function matchingRun(response, branch, sha, workflowId) {
    const references = new Set((response.included ?? []).filter(item =>
        item.type === 'scmGitReferences' && item.attributes.name === branch).map(item => item.id));
    return response.data.filter(run => run.attributes.sourceCommit?.commitSha === sha
        && references.has(run.relationships.sourceBranchOrTag?.data?.id)
        && run.relationships.workflow?.data?.id.toUpperCase() === workflowId.toUpperCase())
        .sort((left, right) => right.attributes.number - left.attributes.number)[0];
}

export function notarizedArtifact(artifacts) {
    const archives = artifacts.filter(item => item.attributes.fileType === 'STAPLED_NOTARIZED_ARCHIVE');
    if (archives.length !== 1) throw new Error('Expected exactly one stapled notarized archive');
    const artifact = archives[0].attributes;
    const url = new URL(artifact.downloadUrl);
    if (url.protocol !== 'https:' || url.hostname !== 'cvws.icloud-content.com'
        || url.username || url.password || !Number.isSafeInteger(artifact.fileSize)
        || artifact.fileSize <= 0 || artifact.fileSize > 1024 ** 3) {
        throw new Error('Invalid notarized artifact URL or size');
    }
    return artifact;
}

async function api(path) {
    const url = new URL(path, apiOrigin);
    if (url.origin !== apiOrigin) throw new Error('Unexpected Apple API origin');
    const now = Math.floor(Date.now() / 1000);
    const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
    const unsigned = encode({ alg: 'ES256', kid: process.env.APPLE_KEY_ID, typ: 'JWT' }) + '.'
        + encode({ iss: process.env.APPLE_ISSUER_ID, iat: now, exp: now + 1200,
            aud: 'appstoreconnect-v1' });
    const token = unsigned + '.' + sign('sha256', Buffer.from(unsigned), {
        key: createPrivateKey(process.env.APPLE_PRIVATE_KEY), dsaEncoding: 'ieee-p1363',
    }).toString('base64url');
    const response = await fetch(url, { headers: { Authorization: `Bearer ${token}` },
        redirect: 'error', signal: AbortSignal.timeout(30000) });
    if (!response.ok) throw new Error(`Apple API HTTP ${response.status}`);
    return response.json();
}

async function list(path) {
    const result = { data: [], included: [] };
    do {
        const page = await api(path);
        result.data.push(...page.data);
        result.included.push(...(page.included ?? []));
        path = page.links?.next;
    } while (path);
    return result;
}

async function main() {
    const [branch, sha, output] = process.argv.slice(2);
    const release = parseBranch(branch);
    if (!/^[a-f0-9]{40}$/.test(sha) || !output) throw new Error('Source SHA and output are required');
    for (const key of ['APPLE_KEY_ID', 'APPLE_ISSUER_ID', 'APPLE_PRIVATE_KEY']) {
        if (!process.env[key]) throw new Error(`Missing ${key}`);
    }
    const deadline = Date.now() + 45 * 60 * 1000;
    let run;
    while (Date.now() < deadline) {
        const response = await list(`/v1/ciProducts/${product}/buildRuns?include=sourceBranchOrTag,workflow&sort=-number&limit=200`);
        run = matchingRun(response, branch, sha, workflow);
        console.log(`Cloud ${branch}: ${run?.attributes.executionProgress ?? 'waiting for run'}`);
        if (run?.attributes.executionProgress === 'COMPLETE') break;
        await setTimeout(60000);
    }
    if (run?.attributes.executionProgress !== 'COMPLETE'
        || run.attributes.completionStatus !== 'SUCCEEDED') {
        throw new Error('Cloud did not finish successfully; previous release stays published');
    }
    const actions = await list(`/v1/ciBuildRuns/${run.id}/actions`);
    const artifacts = [];
    for (const action of actions.data.filter(item => item.attributes.completionStatus === 'SUCCEEDED')) {
        artifacts.push(...(await list(`/v1/ciBuildActions/${action.id}/artifacts`)).data);
    }
    const artifact = notarizedArtifact(artifacts);
    // Signed download URLs are capabilities; never forward the Apple API JWT to storage.
    const response = await fetch(artifact.downloadUrl, { redirect: 'error',
        signal: AbortSignal.timeout(120000) });
    if (!response.ok) throw new Error(`Artifact HTTP ${response.status}`);
    const chunks = [];
    let size = 0;
    for await (const chunk of response.body) {
        size += chunk.length;
        if (size > artifact.fileSize) throw new Error('Artifact exceeds declared size');
        chunks.push(chunk);
    }
    if (size !== artifact.fileSize) throw new Error('Artifact size mismatch');
    await mkdir(output, { recursive: true });
    await writeFile(`${output}/app.zip`, Buffer.concat(chunks));
    await writeFile(`${output}/cloud.json`, JSON.stringify({ ...release, sourceSHA: sha, cloudRun: run.id }));
    console.log(`Downloaded notarized Cloud run ${run.id}, app ${release.version} (${release.build})`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    main().catch(error => { console.error(error.message); process.exitCode = 1; });
}
