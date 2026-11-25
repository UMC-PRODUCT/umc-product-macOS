//  DockScenery.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/25/26.
//

import AppKit
import HomeDomain
import SceneKit

/// Layered paper silhouettes, folds, and cut edges share a small print palette.
@MainActor
final class DockScenery {
    let scene = SCNScene()
    let camera = SCNNode()
    let ink = NSColor(srgbRed: 0.12, green: 0.15, blue: 0.16, alpha: 1)
    let stock = NSColor(srgbRed: 1, green: 0.93, blue: 0.77, alpha: 1)
    let crease = NSColor(srgbRed: 0.65, green: 0.63, blue: 0.54, alpha: 1)
    let alarm = NSColor(srgbRed: 1, green: 0.38, blue: 0.12, alpha: 1)
    let right = SCNNode(), left = SCNNode(), finger = SCNNode()
    let boss = SCNNode(), envelope = SCNNode(), barrier = SCNNode()
    let warning = SCNNode(), bands = SCNNode(), boat = SCNNode()
    let target = SCNNode(), impactMark = SCNNode(), echoMark = SCNNode()
    var actors: [Int: SCNNode] = [:]
    var materials: [NSColor: SCNMaterial] = [:]

    init() {
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 68
        camera.camera?.zNear = 0.03
        camera.camera?.zFar = 140
        scene.rootNode.addChildNode(camera)
        scene.background.contents = stock
        scene.fogColor = stock
        scene.fogStartDistance = 29
        scene.fogEndDistance = 84
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 850
        sun.eulerAngles = SCNVector3(-0.9, -0.6, 0)
        scene.rootNode.addChildNode(sun)
        let sky = SCNNode()
        sky.light = SCNLight()
        sky.light?.type = .ambient
        sky.light?.intensity = 680
        scene.rootNode.addChildNode(sky)
        constructHarbor()
        constructTools()
        decorateWharf()
        // Static pier geometry shares materials. Batching removes hundreds of draw submissions.
        let live = [camera, right, left, boss, envelope, warning, bands, boat, barrier,
                    target, impactMark, echoMark]
        let staticProps = SCNNode()
        for child in scene.rootNode.childNodes where child.light == nil && !live.contains(child) {
            staticProps.addChildNode(child)
        }
        scene.rootNode.addChildNode(staticProps.flattenedClone())
    }

    @discardableResult func shape(
        _ geometry: SCNGeometry, _ color: NSColor, _ x: CGFloat, _ y: CGFloat, _ z: CGFloat,
        parent: SCNNode? = nil
    ) -> SCNNode {
        if materials[color] == nil {
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .lambert
            materials[color] = material
        }
        geometry.materials = [materials[color]!]
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(x, y, z)
        (parent ?? scene.rootNode).addChildNode(node)
        return node
    }

    @discardableResult func box(
        _ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ c: NSColor, _ x: CGFloat, _ y: CGFloat,
        _ z: CGFloat, _ parent: SCNNode? = nil
    ) -> SCNNode {
        shape(SCNBox(width: w, height: h, length: d, chamferRadius: 0), c, x, y, z, parent: parent)
    }

    @discardableResult func orb(
        _ size: CGFloat, _ c: NSColor, _ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ parent: SCNNode
    ) -> SCNNode {
        let sphere = SCNSphere(radius: size)
        sphere.segmentCount = 12
        return shape(sphere, c, x, y, z, parent: parent)
    }

    func ring(_ radius: CGFloat, _ pipe: CGFloat, _ c: NSColor, _ parent: SCNNode) -> SCNNode {
        shape(SCNTorus(ringRadius: radius, pipeRadius: pipe), c, 0, 0, 0, parent: parent)
    }

    private func constructHarbor() {
        let root = scene.rootNode
        box(170, 0.3, 170, crease, 0, -1.5, 0)
        for i in 0..<78 {
            let x = CGFloat((i * 43) % 110 - 55), z = CGFloat((i * 23) % 100 - 50)
            box(CGFloat(1 + i % 6), 0.015, 0.12, stock, x, -1.32, z)
        }
        for i in 0..<26 {
            let hill = SCNCone(topRadius: 0, bottomRadius: CGFloat(4 + i % 8),
                               height: CGFloat(2 + i % 6))
            hill.radialSegmentCount = 4
            let angle = CGFloat(i) * 0.25
            shape(hill, i.isMultiple(of: 3) ? ink : crease, 44 * sin(angle), 0, 44 * cos(angle))
        }
        box(17, 0.85, 24, ink, 0, -0.48, 0)
        for row in -12..<12 {
            let z = CGFloat(row)
            box(16.9, 0.15, 0.965, stock, 0, -0.07, z + 0.5)
            for side in [-1.0, 1.0] {
                let x = CGFloat(side) * 8.2
                if row.isMultiple(of: 3) {
                    box(0.27, 1.05, 0.27, ink, x, 0.48, z)
                    box(0.36, 0.12, 0.36, stock, x, 1.05, z)
                }
            }
            if row.isMultiple(of: 2) { box(0.12, 0.015, 0.7, ink, 0, 0.02, z) }
        }
        for x in [-8.2, 8.2] { box(0.12, 0.12, 24, ink, x, 0.7, 0) }
        for (x, z) in [(-5.0, -2.5), (5.0, -4.0), (0.0, -8.0)] {
            for side in [-1.0, 1.0] {
                box(0.24, 2.9, 0.36, ink, x + side * 1.3, 1.45, z)
            }
            box(3.1, 0.55, 0.42, ink, x, 3, z)
            for j in 0..<7 {
                box(0.23, 0.4, 0.45, stock, x - 1.2 + Double(j) * 0.4, 3, z)
                    .eulerAngles.z = -0.24
            }
        }
        box(2.2, 0.8, 1.6, crease, 0, 0.4, 1)
        root.addChildNode(barrier)
        box(15, 0.25, 0.05, crease, 0, 0.82, -4.2, barrier)
        for j in -7...7 {
            box(0.35, 0.24, 0.06, ink, CGFloat(j), 0.82, -4.2, barrier).eulerAngles.z = 0.25
        }
        for (x, z, height) in [(5.8, -11.0, 5.6), (-6.6, -10.8, 2.9)] {
            box(1.9, height, 2, crease, x, height/2, z)
            box(1.7, height - 0.2, 0.12, stock, x, height/2, z + 1)
            box(0.58, 1, 0.2, ink, x, height - 0.8, z + 1.04)
            let roof = SCNCone(topRadius: 0, bottomRadius: 2.2, height: 1.4)
            roof.radialSegmentCount = 4
            shape(roof, ink, x, height + 0.7, z).eulerAngles.y = .pi/4
        }
        root.addChildNode(boss)
        boss.position = SCNVector3(0, 1.8, -10)
        let shell = shape(SCNCylinder(radius: 1.55, height: 1.1), ink, 0, 0, 0, parent: boss)
        shell.eulerAngles.x = .pi/2
        let face = shape(SCNCylinder(radius: 1.41, height: 0.12), stock, 0, 0, 0.6, parent: boss)
        face.eulerAngles.x = .pi/2
        for x in [-0.5, 0.5] { orb(0.13, ink, x, 0.23, 0.7, boss) }
        let bull = ring(0.46, 0.09, ink, boss)
        bull.position = SCNVector3(0, -0.41, 0.7)
        bull.eulerAngles.x = .pi/2
        root.addChildNode(envelope)
        envelope.position = SCNVector3(0, 1.4, 5)
        letter(envelope, scale: 0.82)
        root.addChildNode(warning)
        _ = ring(1.65, 0.075, alarm, warning)
        _ = ring(1.47, 0.035, ink, warning)
        root.addChildNode(bands)
        for i in -12...12 {
            box(0.28, 0.025, 24, alarm, CGFloat(i) * 0.8, 0.03, 0, bands)
        }
        root.addChildNode(boat)
        boat.position = SCNVector3(-10, -0.8, -5)
        let hull = box(2.4, 0.6, 0.9, ink, 0, 0, 0, boat)
        hull.eulerAngles.z = -0.06
        box(0.06, 2.1, 0.06, ink, 0, 1, 0, boat)
        let sail = SCNCone(topRadius: 0, bottomRadius: 0.85, height: 1.7)
        sail.radialSegmentCount = 3
        shape(sail, stock, 0.18, 1.15, 0, parent: boat).scale.z = 0.09
    }

    private func letter(_ node: SCNNode, scale: CGFloat) {
        box(1.48, 0.99, 0.12, ink, 0, 0, 0, node)
        box(1.4, 0.91, 0.15, stock, 0, 0, 0, node)
        for s in [-1.0, 1.0] {
            box(0.83, 0.045, 0.03, ink, s * 0.35, 0.19, 0.09, node).eulerAngles.z = s * 0.48
        }
        node.scale = SCNVector3(scale, scale, scale)
    }

    private func sign(_ text: String, x: CGFloat, y: CGFloat, z: CGFloat, width: CGFloat) {
        box(width, 0.72, 0.1, ink, x, y, z)
        let glyph = SCNText(string: text, extrusionDepth: 0.12)
        glyph.font = .systemFont(ofSize: 11, weight: .black)
        glyph.flatness = 0.8
        let node = shape(glyph, stock, x, y, z + 0.07)
        let (lo, hi) = node.boundingBox
        let scale = min((width - 0.25) / (hi.x - lo.x), 0.48 / (hi.y - lo.y))
        node.scale = SCNVector3(scale, scale, scale)
        node.pivot = SCNMatrix4MakeTranslation((hi.x + lo.x)/2, (hi.y + lo.y)/2, 0)
    }

    private func decorateWharf() {
        sign("서쪽 · 접수", x: -5, y: 3.6, z: -2.5, width: 3.4)
        sign("동쪽 · 발송", x: 5, y: 3.6, z: -4, width: 3.4)
        sign("접 지 부 두", x: 0, y: 4.12, z: -10, width: 4.4)
        for i in 0..<9 {
            let x = CGFloat(i) * 1.13 - 4.5
            box(1.18, 0.035, 0.035, ink, x, 4.8 + x * x * 0.015, -8)
            let flag = SCNCone(topRadius: 0.28, bottomRadius: 0, height: 0.56)
            flag.radialSegmentCount = 3
            shape(flag, i.isMultiple(of: 2) ? ink : crease, x, 4.5 + x*x*0.015, -8).scale.z = 0.08
        }
        for i in 0..<12 {
            let x: CGFloat = i.isMultiple(of: 2) ? -7.65 : 7.65
            let z = CGFloat(i / 2) * 3.1 - 9
            let parcel = SCNNode()
            parcel.position = SCNVector3(x, 0.36, z)
            parcel.eulerAngles.y = CGFloat(i % 3) * 0.24
            scene.rootNode.addChildNode(parcel)
            box(0.95, 0.7, 1.02, crease, 0, 0, 0, parcel)
            box(0.16, 0.72, 1.04, ink, 0.17, 0, 0, parcel)
            box(0.97, 0.73, 0.08, stock, 0, 0, -0.18, parcel)
        }
        for x in [-13.0, 12.0] {
            box(0.38, 7.2, 0.38, ink, x, 2.2, -13)
            let spar = box(4.2, 0.24, 0.22, ink, x + 1.5, 5.4, -13)
            spar.eulerAngles.z = -0.18
            box(0.04, 2.2, 0.05, ink, x + 3.3, 3.96, -13)
            box(1.1, 0.75, 1.1, crease, x + 3.3, 2.49, -13)
        }
        let front = ring(0.91, 0.07, alarm, target)
        front.eulerAngles.x = .pi/2
        target.position = SCNVector3(0, 1.52, -9.23)
        scene.rootNode.addChildNode(target)
        scene.rootNode.addChildNode(impactMark)
        scene.rootNode.addChildNode(echoMark)
        for (node, radius) in [(impactMark, 0.35), (echoMark, 0.7)] {
            ring(radius, 0.055, ink, node).eulerAngles.x = .pi/2
        }
    }

    private func constructTools() {
        camera.addChildNode(right)
        camera.addChildNode(left)
        right.scale = SCNVector3(0.31, 0.31, 0.31)
        left.scale = right.scale
        for (hand, sign) in [(right, 1.0), (left, -1.0)] {
            let sleeve = box(0.52, 0.85, 0.52, ink, sign * 0.24, -0.41, 0.24, hand)
            sleeve.eulerAngles.z = sign * 0.4
            let palm = orb(0.35, stock, 0, 0.05, 0, hand)
            palm.scale = SCNVector3(0.87, 1.12, 0.68)
            for j in 0..<4 {
                let mount = j == 3 && sign > 0 ? finger : SCNNode()
                hand.addChildNode(mount)
                mount.position = SCNVector3(-sign * 0.18, CGFloat(j) * 0.104 - 0.13, -0.1)
                let digit = orb(0.122, stock, -sign * 0.12, 0, 0, mount)
                digit.scale = SCNVector3(1.85, 0.75, 0.92)
            }
        }
        let stamp = SCNNode()
        right.addChildNode(stamp)
        stamp.position = SCNVector3(-0.27, 0.05, -0.18)
        shape(SCNCylinder(radius: 0.14, height: 0.7), ink, 0, 0, 0, parent: stamp)
        orb(0.235, ink, 0, 0.37, 0, stamp)
        box(0.74, 0.18, 0.65, ink, 0, -0.37, 0, stamp)
        box(0.68, 0.09, 0.6, crease, 0, -0.48, 0, stamp)
        let sheet = SCNNode()
        left.addChildNode(sheet)
        sheet.position = SCNVector3(0.32, 0.08, -0.24)
        sheet.eulerAngles = SCNVector3(-0.8, 0.12, 0.18)
        letter(sheet, scale: 0.8)
    }

    func draw(_ round: DockRound, time: Double, reduced: Bool) {
        camera.position = SCNVector3(round.position.x, 1.58, round.position.y)
        camera.eulerAngles.y = -round.heading
        target.isHidden = !round.exposed
        impactMark.isHidden = round.stampTime <= 0 || round.stampTime > 0.22
        impactMark.position = SCNVector3(round.impactPoint.x, 1.45, round.impactPoint.y)
        impactMark.eulerAngles.y = -round.heading
        echoMark.isHidden = round.echoPoint == nil
        if let echo = round.echoPoint {
            echoMark.position = SCNVector3(echo.x, 1.35, echo.y)
            echoMark.eulerAngles.y = -round.heading
        }
        envelope.isHidden = round.phase != .reception
        barrier.isHidden = round.seal != nil
        boss.eulerAngles.z = round.exposed && !reduced ? sin(time * 4) * 0.08 : 0
        let press = round.stampTime > 0 ? sin(.pi * (0.38 - round.stampTime) / 0.38) : 0
        right.position = SCNVector3(0.35, -0.24 + 0.09 * press, -0.69 - 0.12 * press)
        right.eulerAngles.z = -0.16 + 0.32 * press
        let reach = reduced ? 0 : min(1, press * 2)
        left.position = SCNVector3(-0.52 + 0.26 * reach, -0.47 + 0.23 * reach, -0.70)
        finger.eulerAngles.z = reduced || press > 0 ? 0 : max(0, sin(time * 5)) * 0.48
        warning.isHidden = !round.hasWarning || round.phase == .boss
        warning.position = SCNVector3(round.warningPoint.x, 0.06, round.warningPoint.y)
        bands.isHidden = !(round.hasWarning && round.phase == .boss)
        if !bands.isHidden {
            bands.eulerAngles.y = atan(round.slope)
            for stripe in bands.childNodes {
                stripe.isHidden = abs(stripe.position.x - round.laneCenter(at: 0)) < 2.1
            }
        }
        let active = Set(round.spirits.map(\.id))
        for id in actors.keys.filter({ !active.contains($0) }) {
            actors.removeValue(forKey: id)?.removeFromParentNode()
        }
        for spirit in round.spirits {
            let node: SCNNode
            if let existing = actors[spirit.id] { node = existing }
            else {
                node = SCNNode()
                scene.rootNode.addChildNode(node)
                letter(node, scale: spirit.kite ? 1.28 : 0.92)
                for side in [-1.0, 1.0] {
                    orb(0.08, ink, side * 0.25, -0.06, 0.13, node)
                    box(0.26, 0.13, 0.32, ink, side * 0.38, -0.56, 0.1, node)
                }
                actors[spirit.id] = node
            }
            let attacks = round.attacker == spirit.id && round.hasWarning
            let leap = attacks && !spirit.kite ? max(0, sin((round.beat - 1.9) / 0.6 * .pi)) : 0
            let bob = reduced ? 0 : abs(sin(time * 2.8 + Double(spirit.id))) * 0.2 + leap * 0.7
            let crouched = attacks && round.beat < 1.9 && !spirit.kite
            node.scale.y = (spirit.kite ? 1.28 : 0.92) * (crouched ? 0.65 : 1)
            node.position = SCNVector3(spirit.position.x, (spirit.kite ? 1.6 : 1.05) + bob,
                                       spirit.position.y)
            node.eulerAngles.y = atan2(round.position.x - spirit.position.x,
                                       round.position.y - spirit.position.y)
            node.eulerAngles.z = spirit.kite ? 0.48 : 0
        }
        if round.phase == .won && !reduced { boat.position.z -= 0.02 }
    }
}
