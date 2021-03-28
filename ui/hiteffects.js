class HitEffectCanvas {
	constructor(canvasElement) {
		this.canvas = canvasElement;
		this.canvas.width = Math.floor(Math.min(window.innerWidth / 2, window.innerHeight / 2));
		this.canvas.height = this.canvas.width;
		this.ctx = this.canvas.getContext('2d');
		this.fadeOutMs = 200;
		this.minFontSize = 2;
		this.maxFontSize = 8;
		this.minDamageThreshold = 10;
		this.maxDamageThreshold = 500;
		this.effects = [];
	}

	update() {
		// clear canvas
		this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

		// check if hits are empty
		if (this.effects.length < 1) return;

		// clear expired hits
		this.effects = this.effects.filter((effect) => Date.now() <= effect.endMs);

		// draw each hit
		this.effects.forEach((effect) => {
			const [x, y] = effect.getCoordinates();
			this.drawStroked(effect.damage, x+effect.offsetX, y+effect.offsetY, effect.isHeadshot, effect.endMs - Date.now())
		});
	}

	getFontSize(damage, isHeadshot) {
		damage = Math.min(this.maxDamageThreshold, Math.max(this.minDamageThreshold, damage));
		const prc = 1 - (this.maxDamageThreshold - damage) / (this.maxDamageThreshold - this.minDamageThreshold);
		const fontSize = this.minFontSize + prc * (this.maxFontSize - this.minFontSize);
		return `${fontSize * (isHeadshot ? 1.2 : 1)}vh`;
	}

	drawStroked(damage, x, y, isHeadshot, timeLeft) {
		// calculate opacity
		const alpha = Math.min(timeLeft / this.fadeOutMs, 1.0);

		this.ctx.font = `${this.getFontSize(damage, isHeadshot)} Knewave-Regular`;

		// draw stroke
		this.ctx.strokeStyle = `rgba(0, 0, 0, ${alpha})`;
		this.ctx.lineWidth = isHeadshot ? 5 : 3;
		this.ctx.strokeText(damage, x, y);

		// draw text
		this.ctx.fillStyle = isHeadshot
			? `rgba(183, 58, 58, ${alpha})`
			: `rgba(58, 127, 183, ${alpha})`;
		this.ctx.fillText(damage, x, y);
	}

	addEffect(effect) {
		this.effects.push(effect);
	}
}

class DamageEffect {
	constructor(damage, isHeadshot = false, canvas) {
		this.damage = damage;
		this.isHeadshot = isHeadshot;
		this.canvas = canvas;
		this.baseMs = 800;
		this.randMs = 300;
		this.minDegree = 10;
		this.maxDegree = 70;
		this.offsetX = 0;
		this.offsetY = -100;
		this.maxMult = 120;
		this.slopeVector = this.randomSlopeVector();
		this.startMs = Date.now();
		this.endMs = this.randomEndMs();
	}

	randomSlopeVector() {
		const rads = (randomNumber(this.minDegree, this.maxDegree) * Math.PI) / 180;
		return [Math.cos(rads), Math.sin(rads)];
	}

	randomEndMs() {
		const randomMs = Math.floor(Math.random() * this.randMs) * (this.isHeadshot ? 1.4 : 1);
		return this.startMs + this.baseMs + randomMs;
	}

	getCoordinates() {
		const prc = (Date.now() - this.startMs) / (this.endMs - this.startMs);
		const mult = 1 + d3.easeExpOut(prc) * this.maxMult;
		return this.slopeVector.map(
			(n, i) => i * this.canvas.canvas.width + (1 + i * -2) * (n * mult)
		);
	}
}

function sleep(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

function randomNumber(min, max) {  
    min = Math.ceil(min); 
    max = Math.floor(max); 
    return Math.floor(Math.random() * (max - min + 1)) + min; 
}

// play a sound using webui
function playSound(file, volume = 1) {
	const audio = document.createElement("audio");
	audio.src = file;
	audio.volume = volume;
	audio.autoplay = true;
	audio.controls = false;
	audio.addEventListener("ended", () => audio.remove());
	document.body.appendChild(audio);
}

const damageGivenCanvas = new HitEffectCanvas(document.getElementById("damageGiven"));
const damageTakenCanvas = new HitEffectCanvas(document.getElementById("damageTaken"));

function addGivenEffect(character, damage, isHeadshot, volume) {
	if (damage <= 0) return;
	if (isHeadshot && character != 'off') {
		playSound(character+"/vc_"+character+"_attack0"+(randomNumber(1,8))+".ogg", volume);
	}
	let effect = new DamageEffect(damage, isHeadshot, damageGivenCanvas);
	effect.minDegree = 10;
	effect.maxDegree = 70;
	effect.maxDegree = 70;
	effect.offsetX = 0;
	effect.offsetY = -100;
	effect.slopeVector = effect.randomSlopeVector();
	damageGivenCanvas.addEffect(effect);
}

function addTakenEffect(damage, isHeadshot) {
	if (damage <= 0) return;
	let effect = new DamageEffect(damage, isHeadshot, damageTakenCanvas);
	effect.minDegree = 40;
	effect.maxDegree = 140;
	effect.offsetX = 150;
	effect.offsetY = -50;
	effect.slopeVector = effect.randomSlopeVector();
	damageTakenCanvas.addEffect(effect);
}

function updateCanvases() {
	damageGivenCanvas.update();
	damageTakenCanvas.update();
}

let soundsEnabled = true
let fps = 60;
// sweet 60fps animations
setInterval(updateCanvases, 1000 / fps);

// scenes - combinations of effects

async function playSetCharacterScene(character, volume = 1) {
	soundsEnabled = (character != 'off');
	if (character == 'off') {
		playAwwSound();
		return;
	}
	playSound("announcer/vc_menu_narration_choosechara.ogg");
	playAnnounceCharacterSound(character, 2255, volume)
	playCheerSound(character, 1000, volume);
}

async function playSpawnScene(character, volume = 1) {
	playCheerSound(character, volume);
	playAnnouncerReadySound(character, volume);
	playAnnouncerGoSound(character, 1000, volume);
	playTauntSound(character, 1500, volume);
}

// -----

// individual sound effects

async function playCustomSound(path, delay = 0, volume = 1) {
	if (!soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound(path, volume);
}

async function playAnnouncerReadySound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("announcer/vc_narration_ready.ogg", volume);
}

async function playAnnouncerGoSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("announcer/vc_narration_go.ogg", volume);
}

async function playAnnouncerPraiseSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("announcer/vc_menu_narration_praise0"+(randomNumber(1,5))+".ogg", volume);
}

async function playAnnounceCharacterSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("announcer/vc_narration_characall_"+character+".ogg", volume);
}

async function playConnectedSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("announcer/vc_menu_narration_challengersapproach.ogg", volume);
}

async function playCheerSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("audience/se_audience_cheer_0"+(randomNumber(1,6))+".ogg", volume);
}

async function playAwwSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound("audience/se_audience_death_0"+(randomNumber(1,4))+".ogg", volume);
}

async function playJumpSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound(character+"/vc_"+character+"_jump0"+(randomNumber(1,4))+".ogg", volume);
}

async function playTauntSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound(character+"/vc_"+character+"_appeal0"+(randomNumber(1,3))+".ogg", volume);
}

async function playDeathSound(character, delay = 0, volume = 1) {
	if (character == 'off' || !soundsEnabled) { return; }
	if (delay > 0) { await sleep(delay); }
	playSound(character+"/vc_"+character+"_damagefly0"+(randomNumber(1,2))+".ogg", volume);
}

// ---

//testing functions
async function testGiven() {
	for (var i = 0; i < 25; i++) {
		let damageAmount = randomNumber(20, 5000);
		let headshot = randomNumber(0,1);
		addGivenEffect(damageAmount, headshot);
		await sleep(250);
	}
}
async function testTaken() {
	for (var i = 0; i < 25; i++) {
		let damageAmount = randomNumber(20, 5000);
		let headshot = randomNumber(0,1);
		addTakenEffect(damageAmount, headshot);
		await sleep(250);
	}
}