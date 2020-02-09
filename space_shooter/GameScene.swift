//
//  GameScene.swift
//  space_shooter
//
//  Created by Anna on 29/01/2020.
//  Copyright © 2020 Anna. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield:SKEmitterNode! // переменная, отвечающая за звездное поле
    var player:SKSpriteNode! // переменная игрок
    var scoreLabel:SKLabelNode! // надпись со счетом
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Пыщ: \(score)" // отображение счета
        }
    }
    var gameTimer:Timer! // враги
    var aliens = ["alien", "alien2", "alien3"]
    
    let alienCategory:UInt32 = 0x1 << 1
    let bulletCategory:UInt32 = 0x1 << 1
    
    let motionManager = CMMotionManager()
    var xAccelerate:CGFloat = 0
    
    

    override func didMove(to view: SKView) { // показываем звездное поле на экране
        starfield = SKEmitterNode(fileNamed: "Starfield") // вписали название файла
        starfield.position = CGPoint(x:0, y: 1472) // где будет отображаться
        starfield.advanceSimulationTime(30) // пропустили пару секунд анимации
        self.addChild(starfield) // добавили еще что-то на экран
        
        starfield.zPosition = -1 // фон сделали всегда сзади
        
        player = SKSpriteNode (imageNamed: "shuttle") // добавили главного игрока
        player.position = CGPoint(x: 0, y: -300) // позиция игрока
        player.setScale(2)
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // физика
        self.physicsWorld.contactDelegate = self as? SKPhysicsContactDelegate // отслеживание соприкосновений
        scoreLabel = SKLabelNode(text: "Пыщ: 0")
        scoreLabel.fontName = "AmericanTypewritter-Bold"
        scoreLabel.fontSize = 56
        scoreLabel.fontColor = UIColor.white
        scoreLabel.position = CGPoint(x: -200, y: 520)
        score = 0
        
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAccelerate = CGFloat(acceleration.x) * 0.75 + self.xAccelerate * 0.25
            }
        }
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAccelerate * 50
        
        if player.position.x < -350 {
            player.position = CGPoint(x: 350, y: player.position.y)
        } else if player.position.x > 350 {
            player.position = CGPoint(x: -350, y: player.position.y)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var alienBody:SKPhysicsBody
        var bulletBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bulletBody = contact.bodyA
            alienBody = contact.bodyB
        } else {
            bulletBody = contact.bodyB
            alienBody = contact.bodyA
        }
        
        if (alienBody.categoryBitMask & alienCategory) != 0 && (bulletBody.categoryBitMask & bulletCategory) != 0 {
            collisionElements(bulletNode: bulletBody.node as! SKSpriteNode, alienNode: alienBody.node as! SKSpriteNode)
        }
    }
    
    func collisionElements(bulletNode:SKSpriteNode, alienNode:SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Vzriv")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        
        self.run(SKAction.playSoundFileNamed("vzriv.mp3", waitForCompletion: false))
        
        bulletNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion?.removeFromParent()
        }
        
        score += 10
    }
    
    @objc func addAlien() {
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String]
        let alien = SKSpriteNode(imageNamed: aliens[0])
        let randomPos = GKRandomDistribution(lowestValue: -350, highestValue: 350) // выборка случайных чисел
        let pos = CGFloat(randomPos.nextInt())
        alien.position = CGPoint(x: pos, y: 800)
        alien.setScale(2) // размер в 2 раза больше
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = bulletCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animDuration:TimeInterval = 6 // скорость анимации
        
        var actions = [SKAction]()
        actions.append(SKAction.move(to: CGPoint(x: pos, y: -800) , duration: animDuration))
        actions.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actions))
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }

    func fireBullet() {
        self.run(SKAction.playSoundFileNamed("vzriv.mp3", waitForCompletion: false))
        let bullet = SKSpriteNode(imageNamed: "torpedo")
        bullet.position = player.position
        bullet.position.y += 5 // выстрел чуть выше игрока (на 5 пикс)
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width / 2)
        bullet.physicsBody?.isDynamic = true
        bullet.setScale(2)
        
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.isDynamic = true
        
        self.addChild(bullet)
        
        let animDuration:TimeInterval = 0.3 // скорость анимации
        
        var actions = [SKAction]()
        actions.append(SKAction.move(to: CGPoint(x: player.position.x, y: 800) , duration: animDuration))
        actions.append(SKAction.removeFromParent())
        
        bullet.run(SKAction.sequence(actions))
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
