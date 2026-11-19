const $=id=>document.getElementById(id);let players=[],superAdmin=false,selected=null;
function post(action,target=null,value={}){fetch(`https://${GetParentResourceName()}/action`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,target,value})});}
function toast(t){$('toast').textContent=t;$('toast').style.display='block';setTimeout(()=>$('toast').style.display='none',2800);}
function refresh(){fetch(`https://${GetParentResourceName()}/refresh`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});}
function showPage(page){document.querySelectorAll('.page').forEach(x=>x.classList.add('hidden'));$(page).classList.remove('hidden');document.querySelectorAll('.nav').forEach(x=>x.classList.toggle('active',x.dataset.page===page));$('title').textContent=({dashboard:'Dashboard',players:'Spelers beheren',world:'Wereldbeheer',tools:'Admin tools'})[page];}
function renderPlayers(){
 $('online').textContent=players.length;
 $('recentPlayers').innerHTML=players.slice(0,6).map(p=>`<div class="playerrow"><span>${esc(p.name)} <small>#${p.id}</small></span><small>${p.ping} ms</small></div>`).join('')||'<small>Geen spelers online.</small>';
 const q=($('playerSearch')?.value||'').toLowerCase();
 $('playerGrid').innerHTML=players.filter(p=>(p.name+' '+p.id).toLowerCase().includes(q)).map(p=>`<div class="playercard"><div class="name">${esc(p.name)}　#${p.id}</div><small>Ping: ${p.ping} ms　|　Locatie: ${p.coords.x}, ${p.coords.y}, ${p.coords.z}</small><button data-player="${p.id}" data-act="goto">Ga naar</button><button data-player="${p.id}" data-act="bring">Haal hierheen</button><button data-player="${p.id}" data-act="spectate">Spectate</button><button data-player="${p.id}" data-act="heal">Heal</button><button data-player="${p.id}" data-act="revive">Revive</button><button data-player="${p.id}" data-act="freeze">Freeze</button><button data-player="${p.id}" data-act="return">Terugzetten</button><button data-player="${p.id}" data-act="warn">Waarschuwen</button><button data-player="${p.id}" data-act="kick">Kick</button>${superAdmin?`<button data-player="${p.id}" data-act="ban" class="danger">Ban</button>`:''}</div>`).join('')||'<p>Geen spelers gevonden.</p>';
}
function esc(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
function modal(title,html){$('modalTitle').textContent=title;$('modalContent').innerHTML=html;$('modal').classList.remove('hidden');}
function closeModal(){$('modal').classList.add('hidden');}
function playerAction(act,id){
 selected=id;
 if(['kick','warn','ban'].includes(act)){
  modal(({kick:'Speler kicken',warn:'Speler waarschuwen',ban:'Speler verbannen'})[act],`<label>Reden</label><input id="reason" value="${act==='kick'?'Verwijderd door staff':''}" placeholder="Reden...">${act==='ban'?'<label>Duur in dagen (0 = permanent)</label><input id="days" type="number" min="0" max="3650" value="7">':''}<button class="danger" id="confirm">Bevestigen</button>`);
  $('confirm').onclick=()=>{post(act,id,{reason:$('reason').value,days:$('days')?.value});closeModal();toast('Actie verstuurd.');};
 }else{post(act,id,{});toast('Actie verstuurd.');}
}
window.addEventListener('message',e=>{
 const d=e.data;
 if(d.action==='open'){players=d.data.players||[];superAdmin=!!d.data.super;$('app').classList.remove('hidden');$('resourceBox').classList.toggle('hidden',!superAdmin);renderPlayers();showPage('dashboard');}
 if(d.action==='players'){players=d.players||[];renderPlayers();}
 if(d.action==='close')$('app').classList.add('hidden');
 if(d.action==='announcement'){$('announceText').textContent=d.message;$('announce').classList.remove('hidden');setTimeout(()=>$('announce').classList.add('hidden'),9000);}
});
document.querySelectorAll('.nav').forEach(b=>b.onclick=()=>showPage(b.dataset.page));
document.querySelectorAll('[data-goto]').forEach(b=>b.onclick=()=>showPage(b.dataset.goto));
$('close').onclick=()=>{ $('app').classList.add('hidden');fetch(`https://${GetParentResourceName()}/close`,{method:'POST',body:'{}'});};
$('refresh').onclick=refresh;$('playerSearch').oninput=renderPlayers;$('modalClose').onclick=closeModal;
$('playerGrid').addEventListener('click',e=>{const b=e.target.closest('[data-act]');if(b)playerAction(b.dataset.act,Number(b.dataset.player));});
document.querySelectorAll('[data-action]').forEach(b=>b.onclick=()=>quick(b.dataset.action));
function quick(act){
 if(act==='announce')modal('Server aankondiging','<label>Bericht</label><textarea id="msg" maxlength="250"></textarea><button class="primary" id="go">Versturen</button>');
 if(act==='setweather')modal('Weer instellen','<select id="w"><option>CLEAR</option><option>EXTRASUNNY</option><option>CLOUDS</option><option>OVERCAST</option><option>RAIN</option><option>THUNDER</option><option>FOGGY</option><option>SNOW</option><option>BLIZZARD</option></select><button class="primary" id="go">Toepassen</button>');
 if(act==='settime')modal('Tijd instellen','<label>Uur</label><input id="h" type="number" min="0" max="23" value="12"><label>Minuut</label><input id="m" type="number" min="0" max="59" value="0"><button class="primary" id="go">Toepassen</button>');
 if(act==='cleararea')modal('Voertuigen opruimen','<label>Radius in meters (5-100)</label><input id="r" type="number" value="30" min="5" max="100"><button class="danger" id="go">Opruimen</button>');
 $('go').onclick=()=>{if(act==='announce')post(act,null,{message:$('msg').value});if(act==='setweather')post(act,null,{weather:$('w').value});if(act==='settime')post(act,null,{hour:$('h').value,minute:$('m').value});if(act==='cleararea')post(act,null,{radius:$('r').value});closeModal();toast('Actie verstuurd.');};
}
$('weatherBtn').onclick=()=>post('setweather',null,{weather:$('weather').value});
$('timeBtn').onclick=()=>post('settime',null,{hour:$('hour').value,minute:$('minute').value});
$('clearBtn').onclick=()=>post('cleararea',null,{radius:$('radius').value});
$('announceBtn').onclick=()=>post('announce',null,{message:$('announcement').value});
$('vehicleBtn').onclick=()=>post('spawnvehicle',null,{model:$('vehicle').value});
$('restartBtn').onclick=()=>{if(confirm('Weet je zeker dat je deze resource wilt herstarten?'))post('restartresource',null,{resource:$('resource').value});};
document.addEventListener('keydown',e=>{if(e.key==='Escape'){$('app').classList.add('hidden');closeModal();fetch(`https://${GetParentResourceName()}/close`,{method:'POST',body:'{}'});}});
$('clock').textContent=new Date().toLocaleTimeString('nl-NL',{hour:'2-digit',minute:'2-digit'});
