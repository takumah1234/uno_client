//
//  TCPIP.swift
//  UNO
//
//  Created by apple on 2018/11/20.
//  Copyright © 2018 TakumaHidaka. All rights reserved.
//

import UIKit
import SwiftSocket

class Connection {
    var client: TCPClient!
    let MesEnd = ";"
    var readflag = true
    
    init(Addr: String, SPort: Int32){
        print("connecting....")
        client = TCPClient(address: Addr, port: SPort)
        switch client.connect(timeout: 1){
        case .success:
            print("connect success!!")
            return
        case .failure(let error):
            print(error)
            return
        }
    }

    func sendCommand(command: String){
        switch client.send(string: command).isSuccess{
        case true:
            print("sendCommand():Send: \(command)")
        case false:
            print("sendCommand():SendFalse")
        }
    }
    
    func endConnect(){
        print("endConect")
        client.close()
    }
    
    func recvCommand()->[String]{
        var result = [String]()
        let bufferSize = 1024*10
        if client == nil{
            return [""]
        }else if (readflag){
            guard let readstr = client.read(bufferSize, timeout: 100*60) else{
                print("readerror")
                readflag = false
                return [""]
            }
            if let read = String(bytes: readstr, encoding: .utf8){
                print("recvCommand():Receive: \(read)")
                let arrayread = read.components(separatedBy: MesEnd)
                for mes in arrayread{
                    let nread = mes
                    if !nread.isEmpty{
                        if !nread.contains("\0"){
                            result.append(nread)
                        }
                    }
                }
            }
            if result.isEmpty
            {
                return [""]
            }
            return result
        }
        return [""]
    }
}

class UDPConnection {
    let client:UDPClient!
    
    init(addr: String, servPort: Int32) {
        client = UDPClient(address: addr, port: servPort)
        Send(message: "NewClient")
        let result = Recv()
        print("ConneSuccess: \(result)")
    }
    
    func Send(message: String) {
        let sendMes = client.send(string: message)
        switch sendMes.isSuccess {
        case true:
            print("Send():SendSuccess:Mes:\(message)")
        default:
            print("Send():SendFailed")
        }
    }
    
    func Recv() -> String {
        if let c = client{
            let recvMes = c.recv(1024*10)
            if let data = recvMes.0{
                if let result = String(bytes: data, encoding: .utf8){
                    return result
                }else{
                    print("UDPConnection(): ResultNothing")
                }
            }else{
                print("UDPConnection(): RecvDataNothig")
            }
        }else{
            print("UDPConnection():client nil")
        }
        return ""
    }
    
    func StandByToFunc(function: @escaping ()->Void) {
        DispatchQueue.global(qos: .background).async {
            print("UDPConnection():StandByToFunc(): Start function()")
            function()
            print("UDPConnection():StandByToFunc(): End Function()")
        }
    }
}

/*
 class Connection: NSObject, StreamDelegate {
 /*
 let client:TCPClient!
 let MesEnd = ";"
 
 init(addr: String, servPort: Int32) {
 client = TCPClient(address: addr, port: servPort)
 print("connecting.....")
 switch client.connect(timeout: 1) {
 case .success: break
 case .failure(let error):
 print(error)
 }
 print("connect success!!")
 }
 
 func recvCommand()->[String]{
 var result = [String]()
 let bufferSize = 1024
 guard let RecvedMes = client.read(bufferSize*10) else {return ["NULL"]}
 if let read = String(bytes: RecvedMes, encoding: .utf8) {
 print("recvCommand():Receive: \(read)")
 let arrayread = read.components(separatedBy: MesEnd)
 for mes in arrayread{
 print("recvCommand():ReceivedMessage: \(mes)")
 let nread = mes
 if !nread.isEmpty{
 if !nread.contains("\0"){
 result.append(nread)
 }
 }
 }
 }
 print("recvCommand():result = \(result)")
 if result.isEmpty
 {
 return ["NULL"]
 }
 return result
 }
 
 func sendCommand(command: String){
 let _ = client.send(string: command)
 print("sendCommand():Send: \(command)")
 }
 */
 
 var ServerAddress: CFString! //IPアドレスを指定
 var serverPort: UInt32! = nil //開放するポートを指定
 
 private var inputStream : InputStream!
 private var outputStream: OutputStream!
 
 let MesEnd = ";"
 
 //@brief サーバーとの接続を確立する
 func connect(Addr: String, SPort: UInt32){
 ServerAddress =  NSString(string: Addr) //IPアドレスを指定
 print("connecting.....")
 self.serverPort = SPort
 
 var readStream : Unmanaged<CFReadStream>?
 var writeStream: Unmanaged<CFWriteStream>?
 
 CFStreamCreatePairWithSocketToHost(nil, self.ServerAddress, self.serverPort, &readStream, &writeStream)
 
 self.inputStream  = readStream!.takeRetainedValue()
 self.outputStream = writeStream!.takeRetainedValue()
 
 self.inputStream.delegate  = self
 self.outputStream.delegate = self
 
 self.inputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
 self.outputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
 
 self.inputStream.open()
 self.outputStream.open()
 
 //print("recv:\(recvCommand())")
 
 print("connect success!!")
 }
 
 //@brief inputStream/outputStreamに何かしらのイベントが起きたら起動してくれる関数
 //        今回の場合では、同期型なのでoutputStreamの時しか起動してくれない
 func stream(_ stream:Stream, handle eventCode : Stream.Event){
 //print(stream)
 }
 
 func recvCommand()->[String]{
 var result = [String]()
 if (inputStream == nil)
 {
 return ["ERROR"]
 }
 while(!inputStream.hasBytesAvailable){}
 let bufferSize = 1024
 var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
 let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
 if (bytesRead >= 0) {
 let read = String(bytes: buffer, encoding: String.Encoding.utf8)!
 print("recvCommand():Receive: \(read)")
 let arrayread = read.components(separatedBy: MesEnd)
 for mes in arrayread{
 print("recvCommand():ReceivedMessage: \(mes)")
 let nread = mes
 if !nread.isEmpty{
 if !nread.contains("\0"){
 result.append(nread)
 }
 }
 }
 }
 print("recvCommand():result = \(result)")
 if result.isEmpty
 {
 return ["NULL"]
 }
 return result
 }
 
 //@brief サーバーにコマンド文字列を送信する関数
 func sendCommand(command: String){
 var ccommand = command.data(using: String.Encoding.utf8, allowLossyConversion: false)!
 var cccommand = ccommand
 let text = ccommand.withUnsafeMutableBytes{ bytes in return String(bytesNoCopy: bytes, length: cccommand.count, encoding: String.Encoding.utf8, freeWhenDone: false)!}
 let unsafetext = UnsafePointer<UInt8>(text)
 self.outputStream.write(unsafetext, maxLength: text.utf8.count)
 //self.outputStream.write(unsafetext, maxLength: text.utf8.count)
 print("sendCommand():Send: \(command)")
 }
 
 func endConnect(){
 self.sendCommand(command: "end")
 if (outputStream == nil){
 return
 }
 self.outputStream.close()
 self.outputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
 self.inputStream.close()
 self.inputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
 print("endConnect(): EndConnection")
 }
 }

class SuperTCPClient: TCPClient{

 func superread(_ expectlen: Int, timeout: Int = -1) -> [Byte]? {
 guard let fd:Int32 = self.fd else { return nil }
 print("test0")
 
 var buff = [Byte](repeating: 0x0,count: expectlen)
 print("test1")
 let readLen = c_ytcpsocket_pull(fd, buff: &buff, len: Int32(expectlen), timeout: Int32(timeout))
 print("test2")
 if readLen <= 0 { return nil }
 print("test3")
 let rs = buff[0...Int(readLen-1)]
 print("test4")
 let data: [Byte] = Array(rs)
 print("test5")
 
 return data
 }
 override func read(_ expectlen: Int, timeout: Int = -1) -> [Byte]? {
 let stdout_file = NSString(string: "~/Desktop/stdout.txt").expandingTildeInPath
 _ = freopen(stdout_file, "w", stdout)
 let ret = super.read(expectlen, timeout: timeout)
 return ret
 }
 }
 */
