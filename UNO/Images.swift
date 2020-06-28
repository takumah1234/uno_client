//
//  File.swift
//  UNO
//
//  Created by apple on 2018/11/21.
//  Copyright © 2018 TakumaHidaka. All rights reserved.
//

import Foundation
import SpriteKit

class CardImages{
    let Cardpoints = [Int]()
    let TmpImageName = "UNO_cards_"
    let NilImageName = "nashi"
    var errorNumber = 0
    let CardColor = ["r", "b", "g", "y"]
    let CardNumber = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    var CardColorNumber = [String]()
    // カードの画像を保存する辞書変数
    var CardImage:[String:SKSpriteNode] = [:]
    // 複製したカードの画像を保存する辞書変数
    var ReplicatedCardImages:[String:SKSpriteNode] = [:]
    var FieldCards = [String]()
    
    init() {
        print("readingimages")
        for C in CardColor{
            for N in CardNumber{
                CardColorNumber.append(C+String(N))
            }
        }
        for CN in CardColorNumber{
            let ImageName = TmpImageName+CN
            let tmp = SKSpriteNode(imageNamed: ImageName)
            tmp.size = CGSize(width: tmp.size.width*1.5, height: tmp.size.height*1.5)
            CardImage.updateValue(tmp, forKey: CN)
        }
        CardImage.updateValue(SKSpriteNode(imageNamed: "UNO_cards_nil"), forKey: NilImageName)
    }
    
    func SetCard(Target: String, CardNum: Int, ScreenSize: CGSize, HandNum: Int)->SKSpriteNode{
        var HN = HandNum
        if HN == 1{
            HN = 2
        }
        let StartX = CGFloat(100)
        let InterX = (ScreenSize.width - StartX * 2) / CGFloat(HN-1)
        let posY = ScreenSize.height / 10
        let posX = StartX + InterX * CGFloat(CardNum)
        
        print("SetCard(\(Target))Pos: (\(posX),\(posY))")
        
        if (self.CardColorNumber.contains(Target)){
            self.CardImage[Target]?.position = CGPoint(x: posX, y: posY)
            self.CardImage[Target]?.zPosition = CGFloat(CardNum)
            self.CardImage[Target]?.name = Target
            FieldCards.append(Target)
            return self.CardImage[Target]!
        }else{
            let NilImageNameComp = NilImageName + String(errorNumber)
            errorNumber += 1
            CardImage.updateValue(SKSpriteNode(imageNamed: "UNO_cards_nil"), forKey: NilImageNameComp)
            CardImage[NilImageNameComp]?.name = NilImageNameComp
            FieldCards.append(NilImageNameComp)
            return self.CardImage[NilImageNameComp]!
        }
    }
    
    func SetGraveZone(Target: String,ScreenSize: CGSize) -> SKSpriteNode {
        let posX = ScreenSize.width / 2
        let posY = ScreenSize.height / 2
        
        if let GraveCard = self.CardImage[Target] {
            GraveCard.position = CGPoint(x: posX, y: posY)
            GraveCard.name = Target
            FieldCards.append(Target)
            return GraveCard
        }else{
            let NilImageNameComp = NilImageName + String(errorNumber)
            errorNumber += 1
            CardImage.updateValue(SKSpriteNode(imageNamed: "UNO_cards_nil"), forKey: NilImageNameComp)
            CardImage[NilImageNameComp]?.name = NilImageNameComp
            FieldCards.append(NilImageNameComp)
            return self.CardImage[NilImageNameComp]!
        }
    }
    
    func ReplicateNode(CardName: String, CardNum: Int, ScreenSize: CGSize, HandNum: Int, HandFlag: Bool){
        
        var posX = ScreenSize.width
        var posY = ScreenSize.height
        var HN = HandNum
        
        if HN == 1{
            HN = 2
        }
        
        if (HandFlag){
            let StartX = CGFloat(100)
            let InterX = (ScreenSize.width - StartX * 2) / CGFloat(HN-1)
            posY = ScreenSize.height / 10
            posX = StartX + InterX * CGFloat(CardNum)
            print("SetReplicatedCard(\(CardName))Pos: (\(posX),\(posY))")
        }else{
            posX = ScreenSize.width / 2
            posY = ScreenSize.height / 2
        }
        
        let ReplicatedImage = SKSpriteNode(imageNamed: TmpImageName+CardName)
        ReplicatedImage.position = CGPoint(x: posX, y: posY)
        ReplicatedImage.size = CGSize(width: ReplicatedImage.size.width*1.5, height: ReplicatedImage.size.height*1.5)
        ReplicatedImage.zPosition = CGFloat(CardNum)
        ReplicatedImage.name = TmpImageName+CardName+"2"
        FieldCards.append(TmpImageName+CardName+"2")
        ReplicatedCardImages.updateValue(ReplicatedImage, forKey: CardName)
    }
    
    func DisplayOthersCard(Target: String, CardNum: Int, HandNum: Int, PlayerNum: Int, YourTurn: Int, Screen: SKScene) {
        var HN = HandNum
        var posY = Screen.size.width
        var posX = Screen.size.height
        var Angle = CGFloat(90.0/180.0*Double.pi)
        if HN == 1{
            HN = 2
        }
        let StartY = CGFloat(300)
        let InterY = (Screen.size.height - StartY * 2) / CGFloat(HN-1)
        posY = StartY + InterY * CGFloat(CardNum)
        if (abs(YourTurn - PlayerNum) == 1){
            Angle *= -1
            posX = Screen.size.width / 1000
        }else if (abs(YourTurn-PlayerNum) == 2){
            posX = Screen.size.width / 1000 * 999
        }
        
        let OthersImage = SKSpriteNode(imageNamed: TmpImageName+"back")
        OthersImage.zRotation = Angle
        OthersImage.position = CGPoint(x: posX, y: posY)
        OthersImage.size = CGSize(width: OthersImage.size.width*1.5, height: OthersImage.size.height*1.5)
        OthersImage.zPosition = CGFloat(CardNum)
        OthersImage.name = Target
        FieldCards.append(Target)
        ReplicatedCardImages.updateValue(OthersImage, forKey: Target)
        Screen.addChild(OthersImage)
    }
}
