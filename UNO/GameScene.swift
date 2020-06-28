//
//  GameScene.swift
//  UNO
//
//  Created by apple on 2018/11/19.
//  Copyright © 2018 TakumaHidaka. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene,UITextFieldDelegate {
    // カードの配置を記録する関数
    let Images = CardImages()
    let CommentIcon = SKSpriteNode(imageNamed: "comment_icon")
    
    let addr = "192.168.11.4"
    let GMport:Int32 = 4000
    let ChatPort = 5000
    // ゲームマスター通信用の通信経路
    var GM_Message:GameMaster_Message!
    // チャット用の通信経路
    var Chat_Message:UDPConnection!
    
    let PlayerNum = 3
    let MyStatus = PlayerStatus()
    let fieldStatus = FieldStatus()
    
    // 自分のターンか否かを設定する記憶する変数
    var YourTurnFlag = false
    
    // 捨て札を保存するための変数
    var GraveZoneCard = SKSpriteNode(fileNamed: "UNO_cards_nil")
     
    // 文字入力用の変数
    var textfield:UITextField!
    var myTextView: UITextView! = nil
    var textfieldflag = false
    var RecvMessage:String!
    
    // 対戦結果表示用ラベル
    var ResultLabel:SKLabelNode!
    
    

    override func didMove(to view: SKView) {
        GM_Message = GameMaster_Message(addr: addr, Sport: GMport)
        Chat_Message = UDPConnection(addr: addr, servPort: Int32(ChatPort))
        self.backgroundColor = UIColor.brown
        MyStatus.Start_Init(GM: self.GM_Message)
        fieldStatus.Start_init(GM: self.GM_Message, PlayerNum: self.PlayerNum)
        self.GameInit()
        Update(GetGraveCard: false)
        self.GM_Message.StandByToFunc(function: TurnAndGameJudge)
        ResultLabel = SKLabelNode(fontNamed: "Verdana-bold")
        ResultLabel.text = ""
        ResultLabel.fontSize = 50
        ResultLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        ResultLabel.zPosition = 100
        ResultLabel.fontColor = SKColor.black
        // コメントの表示部分を作成
        myTextView = MakeTextView()
        // コメントの入力部分を作成
        textfield = MakeTextField()
        // コメントの表示部分だけ画面上に表示
        self.view!.addSubview(myTextView)
        //print("MyHand: \(self.MyStatus.Hands):\(self.MyStatus.Hand_Num)")
        CommentIcon.size = CGSize(width: CommentIcon.size.width*0.125, height: CommentIcon.size.height*0.125)
        CommentIcon.position = CGPoint(x: self.size.width-CommentIcon.size.width*0.125, y: self.size.height-CommentIcon.size.height)
        self.addChild(CommentIcon)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.addText(_:)),
            name: NSNotification.Name("NotificationKey"),
            object: nil
        )
        Chat_Message.StandByToFunc {
            self.GetMesAndText()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.MissNotification(_:)),
            name: NSNotification.Name("NotificationKey2"),
            object: nil
        )
        print("Change Scene")
    }
    
    @objc func MissNotification(_ notification: Notification) {
        ResultLabel.text = "Miss"
        self.addChild(ResultLabel)
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.YourTurnFlag){
            let SelectedCard = select_Card(tp: touches)
            if (SelectedCard.1 != Images.CardImage["nashi"]) && (SelectedCard.1 != GraveZoneCard){
                if fieldStatus.GraveJudge(Target: SelectedCard.0){
                    let SendMes = "Release: \(SelectedCard.0)"
                    GM_Message.SendMes(Mes: SendMes)
                    self.MyStatus.ReleaseCard(Target: SelectedCard.0)
                    Update(GetGraveCard: true)
                    self.YourTurnFlag = false
                    self.GM_Message.StandByToFunc(function: TurnAndGameJudge)
                }
            }
        }
        //コメントを打つときにテキストフィールドを表示
        // (何かしらのノードを用意し、そのノードをタップしたら、textfieldflag=trueにして、self.viewにtextfieldを追加する)
        for t in touches{
            let location = t.location(in: self)
            let tN = atPoint(location)
            if (tN == CommentIcon){
                self.textfieldflag = true
                textfield.text = ""
                self.view!.addSubview(textfield)
            }
        }
        //keyboard以外の画面を押すと、keyboardを閉じる処理
        if (self.textfieldflag) && (self.textfield.isFirstResponder) {
            self.textfieldflag = false
            self.textfield.resignFirstResponder()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func Update(GetGraveCard: Bool) {
        /*
         一度全てのノードを消去した後、もう一度ノードを再設置
         この時に同じノードがあるかをチェックして、あれば二つ作成する。
         */
        print("Update(): Hands=>\(self.MyStatus.Hands)")
        print("Update(): Grave=>\(self.fieldStatus.GraveZone)")
        // 一度全てのノードを削除。この時複製したノードも一度削除する。
        for N in self.Images.FieldCards{
            if let targetNode = self.childNode(withName: N){
                targetNode.removeFromParent()
            }
        }
        self.Images.FieldCards = []
        self.Images.ReplicatedCardImages = [:]
        if (GetGraveCard){
            self.fieldStatus.GetGraveCard(GM: self.GM_Message)
        }
        let HandAndGrave = self.MyStatus.Hands + [self.fieldStatus.GraveZone]
        var DuplicationArray = Array(Dictionary(grouping: HandAndGrave){$0}.filter{$0.value.count > 1}.keys)
        // 何かが一致している場合
        if !DuplicationArray.isEmpty{
            if (DuplicationArray.contains(self.fieldStatus.GraveZone)){
                // もし捨て札と手札が一致した場合は、手札に一つ目、捨て札に複製を設置
                DisplayGraveZone()
                DuplicationArray.remove(at: DuplicationArray.index(of: self.fieldStatus.GraveZone)!)
                DisplayHands(DuplicationArray: DuplicationArray)
            }else{
                // もし手札同士が一致した場合は、先に来ている方を一つ目、後のものを複製。
                DisplayGraveZone()
                DisplayHands(DuplicationArray: DuplicationArray)
            }
        }else{
            DisplayGraveZone()
            DisplayHands(DuplicationArray: DuplicationArray)
        }
        var playerNum = 0
        if self.MyStatus.Turn == 0{
            playerNum = 1
        }
        for HandNum in self.fieldStatus.OthersHands{
            if HandNum != 0{
                for i in 1...HandNum{
                    let OthersCardName = "OtherCard"+String(playerNum)+String(i)
                    self.Images.DisplayOthersCard(Target: OthersCardName, CardNum: i, HandNum: HandNum, PlayerNum: playerNum, YourTurn: self.MyStatus.Turn, Screen: self)
                    print("Update():Card(\(OthersCardName))SetComplete")
                    //self.addChild(self.Images.ReplicatedCardImages[OthersCardName]!)
                }
            }
            playerNum += 1
            if self.MyStatus.Turn == playerNum{
                playerNum += 1
            }
        }
        print("Update(): UpdateComplete")
    }
    
    func select_Card(tp: Set<UITouch>) -> (String, SKSpriteNode){
        for t in tp{
            let location = t.location(in: self)
            let tN = atPoint(location)
            for N in Images.CardImage{
                if N.value == tN{
                    print("select_Card(): SelectedCard is \(N.key)")
                    return N
                }
            }
            for N in Images.ReplicatedCardImages{
                if N.value == tN{
                    print("select_Card(): SelectedCard is \(N.key)")
                    return N
                }
            }
        }
        print("select_Card(): SelectedCard nil!")
        return ("nashi", Images.CardImage["nashi"]!)
    }
    
    func DisplayGraveZone() {
        if (self.MyStatus.Hands.contains(self.fieldStatus.GraveZone)){
            Images.ReplicateNode(CardName: self.fieldStatus.GraveZone, CardNum: 0, ScreenSize: self.size, HandNum: self.MyStatus.Hand_Num, HandFlag: false)
            self.GraveZoneCard = Images.ReplicatedCardImages[self.fieldStatus.GraveZone]
        }
        else{
            self.GraveZoneCard = Images.SetGraveZone(Target: self.fieldStatus.GraveZone, ScreenSize: self.size)
        }
        self.addChild(GraveZoneCard!)
        print("DisplayGraveZone(): DisplayGraveZoneComplete")
    }
    
    func DisplayHands(DuplicationArray: [String]) {
        var AfterName = [String]()
        var HandNum = 0
        var CardImage = Images.CardImage["nashi"]
        
        if DuplicationArray.isEmpty {
            for CN in self.MyStatus.Hands{
                CardImage = Images.SetCard(Target: CN, CardNum: HandNum, ScreenSize: self.size, HandNum: self.MyStatus.Hand_Num)
                self.addChild(CardImage!)
                HandNum += 1
            }
        }else{
            for CN in self.MyStatus.Hands{
                if !AfterName.isEmpty && AfterName.contains(CN){
                    Images.ReplicateNode(CardName: CN, CardNum: HandNum, ScreenSize: self.size, HandNum: self.MyStatus.Hand_Num, HandFlag: true)
                    CardImage = Images.ReplicatedCardImages[CN]
                }else{
                    CardImage = Images.SetCard(Target: CN, CardNum: HandNum, ScreenSize: self.size, HandNum: self.MyStatus.Hand_Num)
                }
                AfterName.append(CN)
                self.addChild(CardImage!)
                HandNum += 1
            }
        }
        print("DisplayHands(): DisplayHandsComplete")
    }
    
    func UpdateOthersHand(){
        let flagComment = "othershandChage"
        
        let Mes = GM_Message.GetRecvGMMes()
        if (GM_Message.Analyze(Target: Mes[0], Flag: flagComment)){
            var targetnum = fieldStatus.Turn%PlayerNum
            if (MyStatus.Turn == 0){
                targetnum -= 1
            }else if (MyStatus.Turn == 1){
                if (targetnum == 2){
                    targetnum -= 1
                }
            }
            fieldStatus.OthersHands[targetnum] += Int(Mes[1])!
            print("UpdateOthersHand(): OthersPlayerHandNum Changed")
        }
    }
    
    func GameInit(){
        let HandAndGrave = self.MyStatus.Hands + [self.fieldStatus.GraveZone]
        var DuplicationArray = Array(Dictionary(grouping: HandAndGrave){$0}.filter{$0.value.count > 1}.keys)
        // 何かが一致している場合
        if !DuplicationArray.isEmpty{
            if (DuplicationArray.contains(self.fieldStatus.GraveZone)){
                // もし捨て札と手札が一致した場合は、手札に一つ目、捨て札に複製を設置
                DisplayGraveZone()
                DuplicationArray.remove(at: DuplicationArray.index(of: self.fieldStatus.GraveZone)!)
                DisplayHands(DuplicationArray: DuplicationArray)
            }else{
                // もし手札同士が一致した場合は、先に来ている方を一つ目、後のものを複製。
                DisplayGraveZone()
                DisplayHands(DuplicationArray: DuplicationArray)
            }
        }else{
            DisplayGraveZone()
            DisplayHands(DuplicationArray: DuplicationArray)
        }
        print("GameInit(): GameInit Complete")
    }
    
    func GetFlag_TurnAndGame() -> Bool{
        let flagComment = ["turn", "win", "lose"]
        let Mes = GM_Message.GetRecvGMMes()
        if (GM_Message.Analyze(Target: Mes[0], Flag: flagComment[0])){
            if (Mes[1] == "end"){
                print("GetFlag_TurnAndGame(): GameEnd")
                self.fieldStatus.GameFlag = false
                let Mes2 = GM_Message.GetRecvGMMes()
                if (GM_Message.Analyze(Target: Mes2[0], Flag: flagComment[1])){
                    self.MyStatus.Result = true
                }else if (GM_Message.Analyze(Target: Mes2[0], Flag: flagComment[2])){
                    self.MyStatus.Result = false
                }else{
                    print("GetFlag_TurnAndGame(): OtherMessageRecv=>\(Mes)!")
                }
                return true
            }
            fieldStatus.Turn = Int(Mes[1])!
            if (fieldStatus.Turn % self.PlayerNum == MyStatus.Turn){
                print("GetFlag_TurnAndGame(): YourTurn")
                return false
            }else{
                print("GetFlag_TurnAndGame(): Player\(fieldStatus.Turn % self.PlayerNum)Turn!")
                return true
            }
        }else{
            print("GetFlag_TurnAndGame(): OtherMessageRecv=>\(Mes)!")
            return true
        }
    }
    
    func TurnAndGameJudge() {
        while GetFlag_TurnAndGame() {
            if (!self.fieldStatus.GameFlag){
                if self.MyStatus.Result{
                    ResultLabel.text = "YouWin!"
                }else{
                    ResultLabel.text = "YouLose..."
                }
                self.addChild(ResultLabel)
                break
            }else{
                let Mes = self.GM_Message.GetRecvGMMes()
                let FlagComment = "Turn"
                if (self.GM_Message.Analyze(Target: Mes[0], Flag: FlagComment)){
                    if (Mes[1] != "0"){
                        // 捨て札のカードの更新
                        self.fieldStatus.GetGraveCard(GM: self.GM_Message)
                    }
                }
                // TPの手札の増減を確認
                UpdateOthersHand()
                Update(GetGraveCard: false)
                print("TurnAndGameJudge(): OtherPlayerTurnEnd")
            }
        }
        if (self.fieldStatus.GameFlag){
            YourTurn()
        }
    }
    
    func YourTurn() {
        var DrawFlag = true
        //print("YourTurn(): YourTurnStart!")
        print("Hand:\(self.MyStatus.Hands)")
        print("Grave:\(self.fieldStatus.GraveZone)")
        for MyCard in self.MyStatus.Hands{
            if fieldStatus.GraveJudge(Target: MyCard){
                DrawFlag = false
                break
            }
        }
        if DrawFlag{
            let SendMes = "Draw:\(self.MyStatus.Turn)"
            GM_Message.SendMes(Mes: SendMes)
            while true{
                let Mes = self.GM_Message.GetRecvGMMes()
                if (self.GM_Message.Analyze(Target: Mes[0], Flag: self.MyStatus.Standard[0])){
                    print("YourTurn():DrawCard:\(Mes[1])")
                    self.MyStatus.Draw(Mes: Mes[1])
                    break
                }
            }
        }else{
            let SendMes = "Draw:-1"
            GM_Message.SendMes(Mes: SendMes)
            let _ = self.GM_Message.GetRecvGMMes()
        }
        for MyCard in self.MyStatus.Hands{
            if fieldStatus.GraveJudge(Target: MyCard){
                DrawFlag = false
                break
            }
        }
        Update(GetGraveCard: false)
        if DrawFlag{
            // 出せるカードがないため、ターンを強制終了させる
            let SendMes = "Turn:0"
            GM_Message.SendMes(Mes: SendMes)
            self.GM_Message.StandByToFunc(function: TurnAndGameJudge)
            print("YourTurn(): OthersTurnStart")
        }else{
            let SendMes = "Turn:1"
            GM_Message.SendMes(Mes: SendMes)
            self.YourTurnFlag = true
            print("YourTurn(): YourTurnStart")
        }
    }
     
    // チャット機能部分
    //完了を押すとkeyboardを閉じる処理
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Keyboardを閉じる
        self.Chat_Message.Send(message: textField.text!)
        textField.resignFirstResponder()
        textField.removeFromSuperview()
        
        return true
    }
    // textView に変更を加えるメソッド 適宜必要な処理に読み替えてください
    @objc func addText(_ notification: Notification) {
        guard let text = RecvMessage else {
            return
        }
        myTextView.isScrollEnabled = false
        myTextView.text += text + "\n"
        myTextView.selectedRange = NSRange(location: myTextView.text!.count, length: 0)
        myTextView.isScrollEnabled = true
        
        let scrollY = myTextView.contentSize.height - myTextView.bounds.height
        let scrollPoint = CGPoint(x: 0, y: scrollY > 0 ? scrollY : 0)
        myTextView.setContentOffset(scrollPoint, animated: true)
        print("\(text)")
    }
    func MakeTextView() -> UITextView {
        let Ret = UITextView()
        Ret.frame = CGRect(x:0, y:0, width:self.size.width/3, height:self.size.height/3)
        // 表示させるテキストを設定する.
        Ret.text = ""
        // 枠線の太さを設定する.
        Ret.layer.borderWidth = 1
        // 枠線の色を黒に設定する.
        Ret.layer.borderColor = UIColor.black.cgColor
        // フォントの設定をする.
        Ret.font = UIFont.systemFont(ofSize: CGFloat(20))
        // 左詰めの設定をする.
        Ret.textAlignment = NSTextAlignment.left
        // テキストを編集不可にする.
        Ret.isEditable = false
        
        return Ret
    }
    
    func MakeTextField() -> UITextField {
        let Ret = UITextField()
        //textfieldの位置とサイズを設定
        Ret.frame = CGRect(x: self.view!.frame.width / 2 - 100, y: self.view!.frame.height / 2 - 15, width: 200, height: 30)
        
        //Delegateを自身に設定
        Ret.delegate = self
        
        //アウトラインを表示
        Ret.borderStyle = .roundedRect
        
        //入力している文字を全消しするclearボタンを設定(書いている時のみの設定)
        Ret.clearButtonMode = .whileEditing
        
        //改行ボタンを完了ボタンに変更
        Ret.returnKeyType = .done
        
        //文字が何も入力されていない時に表示される文字(薄っすら見える文字)
        Ret.placeholder = "入力してください"
        return Ret
    }
    
    func GetMesAndText() {
        while true {
            self.RecvMessage = self.Chat_Message.Recv()
            if (self.RecvMessage == ""){
                continue
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("NotificationKey"),
                    object: nil)
            }
        }
    }
    
    /*
     let addr = "192.168.11.4"
     let ChatPort:Int32 = 4000
     let ChatPortTCP:Int32 = 5000
     var Chat_MessageTCP:GameMaster_Message!
     var Chat_Message:UDPConnection!
     // 文字入力用の変数
     var myTextViewTCP: UITextView! = nil
     var RecvMessageTCP = [String?]()
     var textfield:UITextField!
     var myTextView: UITextView! = nil
     var textfieldflag = false
     var RecvMessage:String!
     let CommentIcon = SKSpriteNode(imageNamed: "comment_icon")
     
     override func didMove(to view: SKView) {
     // コメントの表示部分を作成
     myTextView = MakeTextView()
     // コメントの入力部分を作成
     textfield = MakeTextField()
     // コメントの表示部分だけ画面上に表示
     self.view!.addSubview(myTextView)
     
     myTextViewTCP = MakeTextViewTCP()
     self.view!.addSubview(myTextViewTCP)
     
     //print("MyHand: \(self.MyStatus.Hands):\(self.MyStatus.Hand_Num)")
     Chat_MessageTCP = GameMaster_Message(addr: addr, Sport: ChatPortTCP)
     
     Chat_Message = UDPConnection(addr: addr, servPort: ChatPort)
     CommentIcon.size = CGSize(width: CommentIcon.size.width*0.125, height: CommentIcon.size.height*0.125)
     CommentIcon.position = CGPoint(x: self.size.width-CommentIcon.size.width, y: CommentIcon.size.height)
     self.addChild(CommentIcon)
     NotificationCenter.default.addObserver(
     self,
     selector: #selector(self.addText(_:)),
     name: NSNotification.Name("NotificationKey"),
     object: nil
     )
     Chat_Message.StandByToFunc {
     self.GetMesAndText()
     }
     }
     
     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
     //コメントを打つときにテキストフィールドを表示
     // (何かしらのノードを用意し、そのノードをタップしたら、textfieldflag=trueにして、self.viewにtextfieldを追加する)
     for t in touches{
     let location = t.location(in: self)
     let tN = atPoint(location)
     if (tN == CommentIcon){
     self.textfieldflag = true
     textfield.text = ""
     self.view!.addSubview(textfield)
     }
     }
     //keyboard以外の画面を押すと、keyboardを閉じる処理
     if (self.textfieldflag) && (self.textfield.isFirstResponder) {
     self.textfieldflag = false
     self.textfield.resignFirstResponder()
     }
     }
     
     func textFieldShouldReturn(_ textField: UITextField) -> Bool {
     //Keyboardを閉じる
     self.Chat_MessageTCP.SendMes(Mes: textfield.text!)
     
     self.Chat_Message.Send(message: textfield.text!)
     
     textField.resignFirstResponder()
     textField.removeFromSuperview()
     
     return true
     }
     // textView に変更を加えるメソッド 適宜必要な処理に読み替えてください
     @objc func addText(_ notification: Notification) {
     for RecvText in self.RecvMessageTCP{
     if let text = RecvText{
     myTextViewTCP.isScrollEnabled = false
     myTextViewTCP.text += text + "\n"
     myTextViewTCP.selectedRange = NSRange(location: myTextViewTCP.text!.count, length: 0)
     myTextViewTCP.isScrollEnabled = true
     let scrollY = myTextViewTCP.contentSize.height - myTextViewTCP.bounds.height
     let scrollPoint = CGPoint(x: 0, y: scrollY > 0 ? scrollY : 0)
     myTextViewTCP.setContentOffset(scrollPoint, animated: true)
     print("addText(): \(text)")
     }
     }
     if let text = RecvMessage{
     myTextView.isScrollEnabled = false
     myTextView.text += text + "\n"
     myTextView.selectedRange = NSRange(location: myTextView.text!.count, length: 0)
     myTextView.isScrollEnabled = true
     let scrollY = myTextView.contentSize.height - myTextView.bounds.height
     let scrollPoint = CGPoint(x: 0, y: scrollY > 0 ? scrollY : 0)
     myTextView.setContentOffset(scrollPoint, animated: true)
     print("addText(): \(text)")
     }
     }
     
     func MakeTextView() -> UITextView {
     let Ret = UITextView()
     Ret.frame = CGRect(x:0, y:0, width:self.size.width/3, height:self.size.height/3)
     // 表示させるテキストを設定する.
     Ret.text = ""
     // 枠線の太さを設定する.
     Ret.layer.borderWidth = 1
     // 枠線の色を黒に設定する.
     Ret.layer.borderColor = UIColor.black.cgColor
     // フォントの設定をする.
     Ret.font = UIFont.systemFont(ofSize: CGFloat(20))
     // 左詰めの設定をする.
     Ret.textAlignment = NSTextAlignment.left
     // テキストを編集不可にする.
     Ret.isEditable = false
     
     return Ret
     }
     
     func MakeTextField() -> UITextField {
     let Ret = UITextField()
     //textfieldの位置とサイズを設定
     Ret.frame = CGRect(x: self.view!.frame.width / 2 - 100, y: self.view!.frame.height / 2 - 15, width: 200, height: 30)
     
     //Delegateを自身に設定
     Ret.delegate = self
     
     //アウトラインを表示
     Ret.borderStyle = .roundedRect
     
     //入力している文字を全消しするclearボタンを設定(書いている時のみの設定)
     Ret.clearButtonMode = .whileEditing
     
     //改行ボタンを完了ボタンに変更
     Ret.returnKeyType = .done
     
     //文字が何も入力されていない時に表示される文字(薄っすら見える文字)
     Ret.placeholder = "入力してください"
     
     return Ret
     }
     
     func MakeTextViewTCP() -> UITextView {
     let Ret = UITextView()
     Ret.frame = CGRect(x:self.size.width*2/3, y:0, width:self.size.width/3, height:self.size.height/3)
     // 表示させるテキストを設定する.
     Ret.text = ""
     // 枠線の太さを設定する.
     Ret.layer.borderWidth = 1
     // 枠線の色を黒に設定する.
     Ret.layer.borderColor = UIColor.black.cgColor
     // フォントの設定をする.
     Ret.font = UIFont.systemFont(ofSize: CGFloat(20))
     // 左詰めの設定をする.
     Ret.textAlignment = NSTextAlignment.left
     // テキストを編集不可にする.
     Ret.isEditable = false
     
     return Ret
     }
     
     func GetMesAndText() {
     while true {
     self.RecvMessageTCP = self.Chat_MessageTCP!.GetRecvGMMes()
     if (self.RecvMessageTCP[0]!.isEmpty){
     self.Chat_MessageTCP!.Connector.endConnect()
     break
     }
     self.RecvMessage = self.Chat_Message!.Recv()
     print("TCP=>\(self.RecvMessageTCP)")
     print("UDP=>\(self.RecvMessage!)")
     DispatchQueue.main.async {
     NotificationCenter.default.post(
     name: NSNotification.Name("NotificationKey"),
     object: nil)
     }
     }
     }
     
     */
}
