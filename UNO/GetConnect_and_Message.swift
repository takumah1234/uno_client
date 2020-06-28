//
//  GetConnect.swift
//  UNO
//
//  Created by apple on 2018/11/25.
//  Copyright © 2018 TakumaHidaka. All rights reserved.
//

import SpriteKit

class GameMaster_Message{
    let Connector:Connection!
    var RecvMesArray = [String]()
    var SendMesArray = [String]()
    let SplitChar = ":"
    
    init(addr: String, Sport: Int32){
        self.Connector = Connection(Addr: addr, SPort: Sport)
    }
    
    // 得たメッセージを返す
    // 失敗時(何も値を受け取ってない時)にはNULLの文字列を返す
    func GetRecvGMMes()->[String]{
        if (RecvMesArray.isEmpty){
            for recvMes in self.Connector.recvCommand(){
                self.RecvMesArray.append(recvMes)
            }
        }
        if (RecvMesArray.isEmpty){
            return ["NULL"]
        }else{
            print("GetRecvMes():RecvMesArray: \(RecvMesArray)")
            let Mes = self.RecvMesArray.first
            self.RecvMesArray.removeFirst()
            print("GetRecvMes():GetMes: \(Mes!)")
            let target = Mes!.components(separatedBy: SplitChar)
            return target
        }
    }
    
    func SendMes(Mes: String) {
        self.Connector.sendCommand(command: Mes)
        print("Message(): SendMes=>\(Mes)")
        /*
        if (Mes.range(of: "Draw") != nil) || (Mes.range(of: "Release") != nil) || (Mes.range(of: "Turn") != nil){
            self.Connector.sendCommand(command: Mes)
            print("Message():SendMes:\(Mes)")
        }else{
            print("Message():MissSend!")
            NotificationCenter.default.post(
                name: NSNotification.Name("NotificationKey"),
                object: nil)
        }
         */
    }
    
    func StandByToFunc(function: @escaping ()->Void) {
        DispatchQueue.global(qos: .background).async {
            print("StandByToFunc(): Start function()")
            function()
            print("StandByToFunc(): End Function()")
        }
    }
    
    func Analyze(Target: String, Flag: String) -> Bool {
        if (Target == Flag){
            return true
        }else{
            return false
        }
    }
}
