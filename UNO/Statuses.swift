//
//  GameMaster.swift
//  UNO
//
//  Created by apple on 2018/11/26.
//  Copyright © 2018 TakumaHidaka. All rights reserved.
//

class PlayerStatus{
    let Standard = ["myHand", "myturn"]
    
    let Init_Hand_Num = 7
    
    
    var Hands = [String]()
    var Hand_Num = 0
    var Turn = 0
    var Result:Bool!
    
    init() {
    }
    
    func Start_Init(GM: GameMaster_Message){
        while true {
            let Mes = GM.GetRecvGMMes()
            if Mes.isEmpty{
                print("PlayerStatus(): AnyProblemOccured!")
                return
            }
            if (GM.Analyze(Target: Mes[0], Flag: Standard[1])){
                print("PlayerStatus():YourTurn:\(Mes[1])")
                Turn = Int(Mes[1])!
                break
            }
        }
        
        while (Init_Hand_Num > Hand_Num) {
            let Mes = GM.GetRecvGMMes()
            if (GM.Analyze(Target: Mes[0], Flag: Standard[0])){
                print("PlayerStatus():DrawCard:\(Mes[1])")
                Draw(Mes: Mes[1])
            }
        }
    }
    
    func Draw(Mes: String){
        Hands.append(Mes)
        Hand_Num += 1
    }
    
    func ReleaseCard(Target: String) {
        for i in 0...self.Hand_Num-1{
            if (self.Hands[i] == Target){
                self.Hands.remove(at: i)
                self.Hand_Num -= 1
                break
            }
        }
    }
}

class FieldStatus{
    let Standard = ["Grave", "othersturn", "othershand"]
    var OthersHands = [Int]()
    var GraveZone = "None"
    var OthersTurn = [Int]()
    var GameFlag = false
    var Turn = 0
    
    init() {
    }
    
    func Start_init(GM: GameMaster_Message, PlayerNum: Int) {
        GameFlag = true
        // 捨て札の一枚目を表示
        GetGraveCard(GM: GM)
        print("FieldStatus(): GZ: \(GraveZone)")
        var Count = 0
        while (Count < PlayerNum-1) {
            let Mes = GM.GetRecvGMMes()
            if Mes.isEmpty{
                print("FieldStatus(): AnyProblemOccured!")
                return
            }
            if (GM.Analyze(Target: Mes[0], Flag: Standard[1])){
                OthersTurn.append(Int(Mes[1])!)
                Count += 1
            }
        }
        print("\(OthersTurn)")
        Count = 0
        print("FieldStatus(): OthersTurnInfo Get Complete")
        // 各プレイヤーの手札枚数の確認
        while (Count < PlayerNum-1) {
            let Mes = GM.GetRecvGMMes()
            if (GM.Analyze(Target: Mes[0], Flag: Standard[2])){
                OthersHands.append(Int(Mes[1])!)
                Count += 1
            }
        }
        print("\(OthersHands)")
        print("FieldStatus(): OthersHandNumInfo Get Complete")
    }
    
    func GraveJudge(Target: String) -> Bool {
        for GCN in GraveZone{
            if ((Target.range(of: String(GCN))) != nil){
                print("GraveJudge(): GraveZoneJudgeResult=>True")
                return true
            }
        }
        print("GraveJudge(): GraveZoneJudgeResult=>False")
        return false
    }
    
    func GetGraveCard(GM: GameMaster_Message){
        while true {
            let GZ = GM.GetRecvGMMes()
            if (GM.Analyze(Target: GZ[0], Flag: Standard[0])){
                print("GetGraveCard(): GetGraveCard: \(GZ[1])")
                GraveZone = GZ[1]
                break
            }
        }
    }
}
