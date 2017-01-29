//
//  GameScene.swift
//  Rabbit
//
//  Created by ADB on 12/13/16.
//  Copyright © 2016 ADB. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameSceneState {
    case Active, GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var protagonist: SKSpriteNode!
    var sinceTouch : TimeInterval = 0
    var spawnTimer: TimeInterval = 0
    var lastUpdateTime : TimeInterval = 0
    let fixedDelta: TimeInterval = 1.0/60.0 /* standard 60 FPS */
    let scrollSpeed: CGFloat = 160
    var scrollLayer: SKNode!
    var obstacleLayer: SKNode!
    var buttonRestart: MSButtonNode!
    var gameState: GameSceneState = .Active
    var scoreLabel: SKLabelNode!
    var points = 0
    
    
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        physicsWorld.contactDelegate = self
        protagonist = self.childNode(withName: "//protagonist") as! SKSpriteNode
        scrollLayer = self.childNode(withName: "scrollLayer")
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        /* Setup restart button selection handler */
        buttonRestart.selectedHandler = { [unowned self] in
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene!.scaleMode = .aspectFill
            
            /* Restart game scene */
            skView!.presentScene(scene)
            
        }
        
        /* Hide restart button */
        buttonRestart.state = .hidden
        
        /* Reset Score label */
        scoreLabel.text = String(points)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did our hero pass through the 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            /* Increment points */
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
            /* We can return now */
            return
        }
        
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Hero touches anything, game over */
        
        /* Change game state to game over */
        gameState = .GameOver
        
        /* Stop any new angular velocity being applied */
        protagonist.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        protagonist.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        protagonist.removeAllActions()
        
        /* Show restart button */
        buttonRestart.state = .active
        
        let heroDeath = SKAction.run({
            
            /* Put our hero face down in the dirt */
            self.protagonist.zRotation = CGFloat(-90).degreesToRadians()
            /* Stop hero from colliding with anything else */
            self.protagonist.physicsBody?.collisionBitMask = 0
        })
        
        /* Run action */
        protagonist.run(heroDeath)
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            
            /* Apply effect each ground node */
            node.run(shakeScene)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState != .Active { return }
        /* Called when a touch begins */
        
        protagonist.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        protagonist.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
        
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.run(flapSFX)
        
        protagonist.physicsBody?.applyAngularImpulse(1)
        
        sinceTouch = 0
        
    }
    
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= -0.5 * UIScreen.main.bounds.width {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
        if spawnTimer >= 1.5 {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath = Bundle.main.path(forResource: "Obstacle", ofType: "sks")
            let newObstacle = SKReferenceNode(url: URL(fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 0.5 * UIScreen.main.bounds.width, y: CGFloat.random(min: -100, max: 200))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
    }
    
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(1.0 / 60.0)
        let ground1 = scrollLayer.children[0] as! SKSpriteNode
        let ground2 = scrollLayer.children[1] as! SKSpriteNode
        
        /* Get ground node position, convert node position to scene space */
        var groundPosition = scrollLayer.convert(ground1.position, to: self)
        
        /* Check if ground sprite has left the scene */
        if groundPosition.x <= -ground1.size.width {
            
            /* Reposition ground sprite to the second starting position */
            let newPosition = CGPoint(x: ground1.size.width + scrollLayer.convert(ground2.position, to: self).x, y: groundPosition.y)
            
            /* Convert new node position back to scroll layer space */
            ground1.position = self.convert(newPosition, to: scrollLayer)
        }
        
        groundPosition = scrollLayer.convert(ground2.position, to: self)
        
        /* Check if ground sprite has left the scene */
        if groundPosition.x <= -ground2.size.width {
            
            /* Reposition ground sprite to the second starting position */
            let newPosition = CGPoint(x: ground2.size.width + scrollLayer.convert(ground1.position, to: self).x, y: groundPosition.y)
            
            /* Convert new node position back to scroll layer space */
            ground2                                                                                                                         .position = self.convert(newPosition, to: scrollLayer)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameState != .Active { return }
        /* Called before each frame is rendered */
        let velocityY = protagonist.physicsBody?.velocity.dy ?? 0
        
        if velocityY > 400 {
            protagonist.physicsBody?.velocity.dy = 400
        }
    
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            protagonist.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        protagonist.zRotation = protagonist.zRotation.clamped(CGFloat(-20).degreesToRadians(), CGFloat(30).degreesToRadians())
        protagonist.physicsBody!.angularVelocity = protagonist.physicsBody!.angularVelocity.clamped(-2, 2)
        
        sinceTouch += fixedDelta
        
        scrollWorld()
        updateObstacles()
        
        lastUpdateTime = currentTime
        spawnTimer += fixedDelta
    }
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
}
