// Created by euijjang97 on 10/13/26.
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseBranch, matchingRun, notarizedArtifact } from '../xcode-cloud/download_notarized.mjs';

test('deployment branch requires a version and a positive app build number', () => {
    assert.deepEqual(parseBranch('prerelease/0.0.1/4'), { version: '0.0.1', build: '4' });
    for (const branch of ['develop', 'prerelease/0.0.1/04', 'prerelease/0.0.1/0', 'prerelease/1/4']) {
        assert.throws(() => parseBranch(branch));
    }
});

test('Cloud selection matches branch, source SHA and workflow rather than the Cloud counter', () => {
    const run = (id, sha, branch, number) => ({ id, attributes: { sourceCommit: { commitSha: sha }, number },
        relationships: { sourceBranchOrTag: { data: { id: branch } }, workflow: { data: { id: 'workflow' } } } });
    const response = { data: [run('wrong', 'other', 'branch', 9), run('old', 'sha', 'branch', 6),
        run('correct', 'sha', 'branch', 7), run('other-branch', 'sha', 'other', 8)],
        included: [{ id: 'branch', type: 'scmGitReferences', attributes: { name: 'prerelease/0.0.1/4' } }] };
    assert.equal(matchingRun(response, 'prerelease/0.0.1/4', 'sha', 'workflow').id, 'correct');
    assert.equal(matchingRun(response, 'prerelease/0.0.1/4', 'missing', 'workflow'), undefined);
});

test('only a single stapled notarized archive can be distributed', () => {
    const archive = { attributes: { fileType: 'STAPLED_NOTARIZED_ARCHIVE', fileSize: 42,
        downloadUrl: 'https://cvws.icloud-content.com/file.zip' } };
    assert.equal(notarizedArtifact([archive]), archive.attributes);
    for (const artifacts of [[], [archive, archive], [{ attributes: { fileType: 'ARCHIVE_EXPORT' } }],
        [{ attributes: { ...archive.attributes, downloadUrl: 'https://evil.example/app.zip' } }]]) {
        assert.throws(() => notarizedArtifact(artifacts));
    }
});
