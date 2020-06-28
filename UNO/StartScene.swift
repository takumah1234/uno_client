//
//  StartScene.swift
//  UNO
//
//  Created by apple on 2018/11/19.
//  Copyright © 2018 TakumaHidaka. All rights reserved.
//

import SpriteKit

class StartScene: SKScene{
    //let titleLabel = SKLabelNode(fontNamed: "Verdana-bold")
    //var startLabel = SKLabelNode(fontNamed: "Verdana-bold")
    
    override func didMove(to view: SKView) {
        self.backgroundColor = UIColor.brown
        print("Change Scene")
        /*
        titleLabel.text = "UNO"
        titleLabel.fontSize = 70
        titleLabel.position = CGPoint(x: 375, y: 700)
        self.addChild(titleLabel)
        */
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches{
            let location = t.location(in: self.view)
            print("touch point: \(location)")
        }
        /*
        let skView = self.view as SKView?
        let scene = GameScene(size: self.size)
        scene.scaleMode = SKSceneScaleMode.aspectFill
        skView?.presentScene(scene)
        */
    }
}
