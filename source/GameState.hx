package;

import flash.display.BitmapData;
import nme.Assets;
import nme.display.BlendMode;
import nme.display.Graphics;
import nme.display.Sprite;
import org.flixel.FlxG;
import org.flixel.FlxGroup;
import org.flixel.FlxObject;
import org.flixel.FlxPath;
import org.flixel.FlxPoint;
import org.flixel.FlxSprite;
import org.flixel.FlxState;
import org.flixel.FlxText;
import org.flixel.FlxTilemap;
import org.flixel.FlxTypedGroup;
import org.flixel.plugin.photonstorm.FlxButtonPlus;
import org.flixel.tweens.FlxTween;
import org.flixel.tweens.misc.VarTween;
import org.flixel.tweens.util.Ease;
import org.flixel.FlxEmitter;
import org.flixel.FlxParticle;
import org.flixel.plugin.photonstorm.FlxMath;

class GameState extends FlxState
{
	// Groups
	private var guiGroup:FlxGroup;
	public var enemyGroup:FlxTypedGroup<Enemy>;
	private var towerGroup:FlxTypedGroup<Tower>;
	public var bulletGroup:FlxTypedGroup<Bullet>;
	public var emitterGroup:FlxTypedGroup<FlxTypedEmitter<FlxParticle>>;
	public var towerIndicators:FlxTypedGroup<FlxSprite>;
	private var lifeGroup:FlxGroup;
	private var upgradeMenu:FlxGroup;
	private var topGui:FlxGroup;
	
	// Sprites
	private var goal:FlxSprite;
	private var towerRange:FlxSprite;
	private var buildHelper:FlxSprite;
	
	//Texts
    public var moneyText:FlxText;
	private var centerText:FlxText;
	private var enemyText:FlxText;
	private var waveText:FlxText;
	private var tutText:FlxText;
	
	// Buttons
	private var towerButton:FlxButtonPlus;
	private var rangeButton:FlxButtonPlus;
	private var damageButton:FlxButtonPlus;
	private var firerateButton:FlxButtonPlus;
	private var nextWaveButton:FlxButtonPlus;
	private var speedButton:FlxButtonPlus;
		
	// Other objects
	private var tween:FlxTween;
	private var map:FlxTilemap;
	private var path:FlxPath;
	
	private var towerSelected:Tower = null;
	
	// Vars
	private var speed:Int = 1;
	public var money:Int = 50;
	private var lives:Int = 9;
	
	public var wave:Int = 0;
	private var waveCounter:Int = 0;
	
	public var enemiesToKill:Int = 0;
	public var enemiesToSpawn:Int = 0;
	
	private var spawnCounter:Int = 0;
	private var spawnIntervall:Int = 1;
	
	public var towerPrice:Int = 8;
	
	private var buildingMode:Bool = false;
	private var gameOver:Bool = false;
	
	private var upgradeHasBeenBought:Bool = false;
	
	override public function create():Void
	{
		R.GS = this;
		
		FlxG.play("assets/sfx/Select.mp3");
		FlxG.playMusic("assets/sfx/TD2.mp3");
		FlxG.bgColor = FlxG.WHITE;
		FlxG.timeScale = 1;
		
		map = new FlxTilemap();
		map.loadMap(Assets.getText("assets/tilemap/mapCSV_Group2_Map1.csv"), "assets/img/tileset.png");
		path = map.findPath(new FlxPoint(8 * 3 + 4, 0), new FlxPoint(8 * 32 + 4, 8 * 6));
		
		enemyGroup = new FlxTypedGroup();
		towerGroup = new FlxTypedGroup();
		towerIndicators = new FlxTypedGroup();
		bulletGroup = new FlxTypedGroup();
		emitterGroup = new FlxTypedGroup();
		lifeGroup = new FlxGroup();
		topGui = new FlxGroup();
		
		goal = new FlxSprite(245, 43, "assets/img/goal.png");
		
		var guiUnderlay:FlxSprite = new FlxSprite(0, FlxG.height - 16);
		guiUnderlay.makeGraphic(FlxG.width, 16, FlxG.WHITE);
		
		createGUI();
		createUpradeMenu();
		createLives();
		
		centerText = new FlxText( -200, FlxG.height / 2 - 20, FlxG.width, "", 16); 
		centerText.alignment = "center";
		centerText.shadow = FlxG.BLACK;
		centerText.color = FlxG.WHITE;
		centerText.useShadow = true;
		centerText.blend = BlendMode.INVERT;
		
		buildHelper = new FlxSprite(0, 0);
		buildHelper.makeGraphic(8, 8);
		buildHelper.visible = false;
		buildHelper.alpha = 0.5;
		
		moneyText = new FlxText(0, 2, FlxG.width - 2, "$: " + money, 8);
		moneyText.color = FlxG.WHITE;
		moneyText.alignment = "right";
		topGui.add(moneyText);
		
		enemyText = new FlxText(120, 2, FlxG.width, "Wave");
		enemyText.color = FlxG.WHITE;
		enemyText.visible = false;
		topGui.add(enemyText);
		
		waveText = new FlxText(222, 2, FlxG.width, "Wave");
		waveText.color = FlxG.WHITE;
		waveText.visible = false;
		topGui.add(waveText);
		
		towerRange = new FlxSprite(0, 0);
		towerRange.visible = false;
		
		//Add things in correct order
		add(map);
		
		add(bulletGroup);
		add(emitterGroup);
		add(enemyGroup);
		add(towerRange);
		add(towerGroup);
		add(towerIndicators);
		add(goal);
		add(lifeGroup);
		
		add(buildHelper);
		add(guiUnderlay);
		add(guiGroup);
		add(upgradeMenu);
		add(topGui);	
		add(centerText);
		
		// watches
		FlxG.watch(FlxG.mouse, "x");
		FlxG.watch(FlxG.mouse, "y");
		
		tween = new FlxTween(3);
		killedWave();
	}
	
	private function createGUI():Void
	{
		guiGroup = new FlxGroup();
		
		var buttonYOffset:Int = 18;
		
		towerButton = new FlxButtonPlus(2, FlxG.height - buttonYOffset, buildTowerCallback, null, "Buy [T]ower ($" + towerPrice + ")", 120);
		nextWaveButton = new FlxButtonPlus(120, FlxG.height - buttonYOffset, nextWaveCallback, null, "[N]ext Wave");
		speedButton = new FlxButtonPlus(FlxG.width - 20, FlxG.height - buttonYOffset, speedButtonCallback, null, "x1", 20);
		
		R.modifyButton(towerButton, 100);
		R.modifyButton(nextWaveButton);
		R.modifyButton(speedButton);
		
		tutText = new FlxText(nextWaveButton.x, nextWaveButton.textNormal.y, FlxG.width, "Click on a Tower to Upgrade it!");
		tutText.visible = false;
		tutText.color = FlxG.BLACK;
		
		guiGroup.add(towerButton);
		guiGroup.add(nextWaveButton);
		guiGroup.add(speedButton);
		guiGroup.add(tutText);
	}
	
	private function createUpradeMenu():Void
	{
		upgradeMenu = new FlxGroup();
		
		var backButton:FlxButtonPlus = new FlxButtonPlus(2, FlxG.height - 18, toggleUpgradeMenu, [false], "<", 20);
		R.modifyButton(backButton, 20);
		
		rangeButton = new FlxButtonPlus(30, FlxG.height - 18, upgradeRangeCallback, null, "Range ++");
		R.modifyButton(rangeButton);
		
		damageButton = new FlxButtonPlus(120, FlxG.height - 18, upgradeDamageCallback, null, "Damage ++");
		R.modifyButton(damageButton);
		
		firerateButton = new FlxButtonPlus(220, FlxG.height - 18, upgradeFirerateCallback, null, "Firerate ++");
		R.modifyButton(firerateButton);
		
		upgradeMenu.add(backButton);
		upgradeMenu.add(rangeButton);
		upgradeMenu.add(damageButton);
		upgradeMenu.add(firerateButton);
		
		upgradeMenu.visible = false;
	}
	
	private function createLives():Void
	{
		for (i in 0...9) {
			var cur:Int = lifeGroup.length + 1;
			
			var row:Int = Math.ceil(cur / 3);
			var colnum:Int = cur;
			while (colnum > 3) colnum -= 3;
			
			var xPos:Float = goal.x + 5 + 4 * (colnum - 1);
			var yPos:Float = goal.y + 5 + 4 * (row - 1);
		
			var life:FlxSprite = new FlxSprite(xPos, yPos);
			life.makeGraphic(2, 2, FlxG.WHITE);
			lifeGroup.add(life);
		}
	}
	
	override public function destroy():Void
	{
		super.destroy();
	}

	override public function update():Void
	{
		moneyText.text = "$: " + money;
		enemyText.text = "Enemies left: " + (enemiesToKill);
		
		if (moneyText.size > 8) moneyText.size --;
		if (enemyText.size > 8) enemyText.size --;
		if (waveText.size > 8) waveText.size --;
			
		if (FlxG.keys.justReleased("T")) buildTowerCallback(true); 
		if (FlxG.keys.justReleased("SPACE")) speedButtonCallback(true); 
		if (FlxG.keys.justReleased("R")) FlxG.resetState(); 
		if (FlxG.keys.justReleased("N")) nextWaveCallback(true); 
		if (FlxG.keys.justReleased("ESCAPE")) escapeBuilding(); 
		if (FlxG.keys.justReleased("ONE")) upgradeRangeCallback(); 
		if (FlxG.keys.justReleased("TWO")) upgradeDamageCallback(); 
		if (FlxG.keys.justReleased("THREE")) upgradeFirerateCallback(); 
		
		if (buildingMode) {
			buildHelper.x = FlxG.mouse.x - (FlxG.mouse.x % 8);
			buildHelper.y = FlxG.mouse.y - (FlxG.mouse.y % 8);
			updateRangeSprite();
		}
		
		if (FlxG.mouse.justReleased()) {
			if (buildingMode) 
				buildTower();
			else {
				
				for (i in 0...towerGroup.length) {
					var tower = towerGroup.members[i];
					if (FlxMath.pointInCoordinates(cast(FlxG.mouse.x), cast(FlxG.mouse.y), cast(tower.x), cast(tower.y), 8, 8)) {
						towerSelected = towerGroup.members[i];
						toggleUpgradeMenu(true);
						updateUpgradeLabels();
						break;
					}
					else if (FlxG.mouse.y < FlxG.height - 20) {
						toggleUpgradeMenu(false);
					}
				}
			}
		}
		
		FlxG.overlap(enemyGroup, goal, hitGoal);
		FlxG.overlap(bulletGroup, enemyGroup, hitEnemy);
		
		if (enemiesToKill == 0 && towerGroup.length > 0) {
			waveCounter -= cast(FlxG.timeScale);
			nextWaveButton.text = "[N]ext Wave in " + Math.ceil(waveCounter / FlxG.framerate);
			if (waveCounter <= 0) spawnWave();
		}
		else {
			spawnCounter += cast(FlxG.timeScale);
			if (spawnCounter > spawnIntervall * FlxG.framerate && enemiesToSpawn > 0)
				spawnEnemy();
		}
		
		super.update();
	}	
	
	private function hitGoal(enemy:FlxObject, goal:FlxObject):Void
	{
		lives --;
		var enem:Enemy = cast(enemy);
		enem.moneyGain = false;
		enemy.kill();
		
		if (lives >= 0) lifeGroup.members[lives].kill();
		if (lives == 0) loseGame();
		
		FlxG.play("assets/sfx/Hurt.mp3");
	}
	
	private function hitEnemy(bullet:FlxObject, enemy:FlxObject):Void
	{
		var _bullet:Bullet = cast(bullet);
		
		enemy.hurt(_bullet.damage);
		bullet.kill();
		enemy.flicker(0.1);
		FlxG.play("assets/sfx/EnemyHit.mp3");
		
		if (!enemy.alive) enemyText.flicker(0.2);
	}
	
	private function buildTowerCallback(Skip:Bool = false):Void
	{
		if ((!guiGroup.visible || towerPrice > money) && !Skip) return;
		
		buildingMode = !buildingMode;
		towerRange.visible = !towerRange.visible;
		
		playSelectSound();
		buildHelper.visible = buildingMode;
	}
	
	private function speedButtonCallback(Skip:Bool = false):Void
	{
		if (!guiGroup.visible && !Skip) return;
		
		if (speed < 3) speed += 1;
		else speed = 1;
		
		FlxG.timeScale = speed;
		speedButton.text = "x" + speed;
		
		playSelectSound();
	}
	
	private function escapeBuilding():Void
	{
		toggleUpgradeMenu(false);
		buildingMode = false;
		buildHelper.visible = buildingMode;
	}
	
	private function nextWaveCallback(Skip:Bool = false):Void
	{
		if (!guiGroup.visible && !Skip) return;
		if (enemiesToKill > 0) return;
		
		spawnWave();
		playSelectSound();
	}
	
	private function resetCallback(Skip:Bool = false):Void
	{
		if (!guiGroup.visible && !Skip) return;
		
		FlxG.resetState();
		playSelectSound();
	}
	
	private function buildTower():Void
	{
		// Can't place towers on GUI
		if (FlxG.mouse.y > FlxG.height - 16) return;
		
		// Can't buy towers without money
		if (money < towerPrice) {
			FlxG.play("assets/sfx/Deny.mp3");
			escapeBuilding();
			return;
		}
		
		// Snap to grid
		var xPos:Float = FlxG.mouse.x - (FlxG.mouse.x % 8);
		var yPos:Float = FlxG.mouse.y - (FlxG.mouse.y % 8);
		
		// Can't place towers on other towers
		for (i in 0...towerGroup.length) {
			var tower:Tower = towerGroup.members[i];
			if (tower.x == xPos && tower.y == yPos) {
				FlxG.play("assets/sfx/Deny.mp3");
				escapeBuilding();
				return;
			}
		}
		
		//Can't place towers on the road
		if (map.getTile(cast(xPos / 8), cast(yPos / 8)) == 0) {
			FlxG.play("assets/sfx/Deny.mp3");
			escapeBuilding();
			return;
		}
		
		var tower:Tower = new Tower(xPos, yPos);
		tower.index = towerGroup.length - 1;
		towerGroup.add(tower); 
		
		FlxG.play("assets/sfx/Build.mp3");
		
		moneyText.flicker(0.1);
		money -= towerPrice;
		towerPrice += cast(towerPrice * 0.3);
		towerButton.text = "Buy [T]ower ($" + towerPrice + ")";
		escapeBuilding();
	}
	
	private function playSelectSound():Void { FlxG.play("assets/sfx/Select.mp3"); } 
	
	private function announceWave(End:Bool = false):Void
	{
		centerText.x = -200;
		centerText.text = "Wave " + wave;
		if (End) centerText.text = "Game Over! :(";
	
		var completeFunction:Dynamic = hideText;
		if (End) completeFunction = null;
		
		var xTween:VarTween = new VarTween(completeFunction);
		xTween.tween(centerText, "x", 0, 2, Ease.expoOut);
		tween = addTween(xTween);
		
		waveText.text = "Wave: " + wave;
		waveText.size = 16;
		waveText.visible = true;
	}
	
	private function hideText():Void
	{
		var xTween:VarTween = new VarTween();
		xTween.tween(centerText, "x", FlxG.width, 2, Ease.expoIn);
		tween = addTween(xTween);
	}
	
	private function spawnWave():Void
	{
		if (gameOver) return;
		
		wave ++;
		announceWave();
		enemiesToKill = 5 + wave;
		enemiesToSpawn = enemiesToKill;
		
		nextWaveButton.visible = false;
		if (!upgradeHasBeenBought) tutText.visible = true;
		
		enemyText.visible = true;
		enemyText.size = 16;
	}
	
	private function spawnEnemy():Void
	{
		enemiesToSpawn --;
		
		var enemy:Enemy = new Enemy(3 * 8 + 4, - 20);
		enemy.followPath(path, 20 + wave, 0, true);
		enemyGroup.add(enemy);
		spawnCounter = 0;
	}
	
	public function killedWave():Void
	{
		if (wave != 0) FlxG.play("assets/sfx/WaveDefeated.mp3");
		
		waveCounter = 3 * FlxG.framerate;
		
		nextWaveButton.visible = true;
		tutText.visible = false;
		
		enemyText.visible = false;
	}
	
	private function loseGame():Void
	{
		gameOver = true;
		
		enemyGroup.kill();
		towerGroup.kill();
		upgradeMenu.kill();
		towerIndicators.kill();
		towerRange.kill();
		
		announceWave(true);
		
		towerButton.text = "[R]estart";
		towerButton.setOnClickCallback(resetCallback);
		
		FlxG.play("assets/sfx/GameOver.mp3");
	}
	
	private function updateRangeSprite():Void
	{
		var spriteToAttach:FlxSprite = buildHelper; 
		var range:Int = 40;
		
		if (!buildingMode) {
			spriteToAttach =  towerSelected;
			range = towerSelected.range;
		}
		

		towerRange.makeGraphic(FlxG.width, FlxG.height, 0, true);
		towerRange.alpha = 0.2;
		towerRange.visible = true;
		
		var gfx:Graphics = FlxG.flashGfx;
		gfx.clear();
		gfx.beginFill(0xFFFFFF);
		gfx.drawCircle(spriteToAttach.getMidpoint().x, spriteToAttach.getMidpoint().y, range);
		gfx.endFill();
		
		towerRange.pixels.draw(FlxG.flashGfxSprite);
		towerRange.dirty = true;
		
		add(towerRange);
	}
	
	// Tower upgrades 
	
	private function toggleUpgradeMenu(On:Bool):Void
	{
		upgradeMenu.visible = On;
		guiGroup.visible = !On;
		towerRange.visible = On;
		
		if (!On) towerSelected = null;
		else updateUpgradeLabels();
		
		if (On) playSelectSound();
	}
	
	private function upgradeRangeCallback():Void
	{
		if (!upgradeMenu.visible) return;
		
		if (money >= towerSelected.range_PRIZE) {
			money -= towerSelected.range_PRIZE;
			towerSelected.upgradeRange();
			upgradHelper();
		}
	}
	
	private function upgradeDamageCallback():Void
	{
		if (!upgradeMenu.visible) return;
		
		if (money >= towerSelected.damage_PRIZE) {
			money -= towerSelected.damage_PRIZE;
			towerSelected.upgradeDamage();
			upgradHelper();
		}
	}
	
	private function upgradeFirerateCallback():Void
	{
		if (!upgradeMenu.visible) return;
		
		if (money >= towerSelected.firerate_PRIZE) {
			money -= towerSelected.firerate_PRIZE;
			towerSelected.upgradeFirerate();
			upgradHelper();
		}
	}
	
	private function upgradHelper():Void
	{
		moneyText.flicker(0.2);
		updateUpgradeLabels();
		playSelectSound();
		upgradeHasBeenBought = true;
	}
	
	private function updateUpgradeLabels():Void
	{
		rangeButton.text = "Range (" + towerSelected.range_LEVEL + "): $" + towerSelected.range_PRIZE; 
		damageButton.text = "Damage (" + towerSelected.damage_LEVEL + "): $" + towerSelected.damage_PRIZE; 
		firerateButton.text = "Firerate (" + towerSelected.firerate_LEVEL + "): $" + towerSelected.firerate_PRIZE; 
		
		updateRangeSprite();
	}
}