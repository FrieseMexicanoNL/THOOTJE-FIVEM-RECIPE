const $=s=>document.querySelector(s), $$=s=>[...document.querySelectorAll(s)];
const labels={health:'Gezondheid',armor:'Bewapening',hunger:'Honger',thirst:'Dorst',stamina:'Uithouding',oxygen:'Zuurstof',voice:'Spraakstatus',street:'Straatnaam',compass:'Kompas / richting',time:'Tijd',player:'Speler-ID',job:'Baan / functie',cash:'Contant geld',bank:'Bankrekening',vehicle:'Voertuig HUD',vehicleStreet:'Voertuig straatinfo'};
const defaults={enabled:{health:true,armor:true,hunger:true,thirst:true,stamina:true,oxygen:true,voice:true,street:true,compass:true,time:true,player:true,job:true,cash:true,bank:true,vehicle:true,vehicleStreet:true},color:'cyan',scale:100,opacity:92,shape:'rounded',compact:false,positions:{}};
const colors={cyan:'#35e0d0',purple:'#a78bfa',orange:'#ffb454',red:'#ff647c',blue:'#60a5fa',lime:'#a3e635'};
let settings=structuredClone(defaults),dragging=null,dragOffset={x:0,y:0};
const widgets=['health','armor','hunger','thirst','stamina','oxygen','voice','street','time','player','job','cash','bank','vehicle'];
function apply(){
 document.documentElement.style.setProperty('--accent',colors[settings.color]||colors.cyan);
 document.documentElement.style.setProperty('--scale',settings.scale/100);
 document.documentElement.style.setProperty('--opacity',settings.opacity/100);
 document.body.classList.toggle('sharp',settings.shape==='sharp');document.body.classList.toggle('compact',!!settings.compact);
 $$('[data-module]').forEach(el=>{let m=el.dataset.module;let enabled=settings.enabled[m]!==false;el.style.display=enabled?'':'none'});
 Object.entries(settings.positions||{}).forEach(([id,p])=>{let el=document.querySelector(`#hud [data-module="${id}"]`);if(el){el.style.left=p.x+'px';el.style.top=p.y+'px';el.style.right='auto';el.style.bottom='auto'}});
}
function renderToggles(){
 $('#toggles').innerHTML=widgets.map(id=>`<div class="toggle ${settings.enabled[id]!==false?'on':''}" data-toggle="${id}"><span>${labels[id]}</span><span class="switch"></span></div>`).join('');
 $$('[data-toggle]').forEach(el=>el.onclick=()=>{let id=el.dataset.toggle;settings.enabled[id]=! (settings.enabled[id]!==false);el.classList.toggle('on',settings.enabled[id]);apply();save()});
}
function save(){fetch(`https://${GetParentResourceName()}/save`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(settings)});$('#saved').textContent='Opgeslagen ✓'}
function openEditor(open){$('#editor').classList.toggle('hidden',!open)}
function updateBar(id,val){let n=Math.max(0,Math.min(100,Number(val)||0));$('#'+id).textContent=Math.round(n);$('#'+id+'Bar').style.width=n+'%'}
function euro(v){return '€'+Number(v||0).toLocaleString('nl-NL')}
function update(d){
 if(!d)return;
 ['health','armor','hunger','thirst'].forEach(k=>{if(d[k]!=null)updateBar(k,d[k])});
 ['stamina','oxygen'].forEach(k=>{if(d[k]!=null)$('#'+k).textContent=Math.round(d[k])+'%'});
 $('#voice').textContent=(d.talking?'● PRATEN':'● STIL');$('#voice').style.color=d.talking?'#a3e635':'var(--accent)';
 $('#street').textContent=d.street||'';$('#crossing').textContent=d.crossing||'';
 $('#player').textContent='ID '+(d.player||0);$('#job').textContent=d.job||'Werkloos';$('#time').textContent=d.time||'';
 $('#cash').textContent=euro(d.cash);$('#bank').textContent=euro(d.bank);
 if(d.vehicle){$('#vehicle').classList.add('show');$('#speed').textContent=String(d.vehicle.speed||0).padStart(3,'0');$('#fuel').textContent=Math.round(d.vehicle.fuel||0)+'%';$('#engine').textContent=Math.round(d.vehicle.engine||0)+'%';$('#fuelBar').style.width=Math.max(0,Math.min(100,d.vehicle.fuel||0))+'%'}else $('#vehicle').classList.remove('show');
}
window.addEventListener('message',e=>{let m=e.data;if(m.action==='update')update(m.data);if(m.action==='editor')openEditor(m.open);if(m.action==='settings'){settings={...structuredClone(defaults),...m.settings,enabled:{...defaults.enabled,...(m.settings.enabled||{})}};apply();renderToggles();$('#scale').value=settings.scale;$('#opacity').value=settings.opacity;$('#shape').value=settings.shape;$('#compact').checked=settings.compact}if(m.action==='reset'){settings=structuredClone(defaults);apply();renderToggles()}});
$$('.tabs button').forEach(b=>b.onclick=()=>{$$('.tabs button').forEach(x=>x.classList.remove('active'));b.classList.add('active');$$('.tab-page').forEach(p=>p.classList.add('hidden'));$('#'+b.dataset.tab).classList.remove('hidden')});
$$('[data-color]').forEach(b=>{b.style.setProperty('--swatch',colors[b.dataset.color]);b.onclick=()=>{settings.color=b.dataset.color;apply();save()}});
$('#scale').oninput=e=>{settings.scale=+e.target.value;apply();save()};$('#opacity').oninput=e=>{settings.opacity=+e.target.value;apply();save()};$('#shape').onchange=e=>{settings.shape=e.target.value;apply();save()};$('#compact').onchange=e=>{settings.compact=e.target.checked;apply();save()};
function close(){fetch(`https://${GetParentResourceName()}/close`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'})}
$('#close').onclick=close;$('#done').onclick=close;
$('#reset').onclick=()=>fetch(`https://${GetParentResourceName()}/reset`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
document.addEventListener('keydown',e=>{if(e.key==='Escape')close()});
// Drag widgets rechtstreeks in de game. Draggen wordt alleen actief in de editor.
$('#hud').addEventListener('mousedown',e=>{if($('#editor').classList.contains('hidden'))return;let el=e.target.closest('[data-module]');if(!el)return;dragging=el;let r=el.getBoundingClientRect();dragOffset={x:e.clientX-r.left,y:e.clientY-r.top};el.style.cursor='grabbing'});
document.addEventListener('mousemove',e=>{if(!dragging)return;let x=e.clientX-dragOffset.x,y=e.clientY-dragOffset.y;dragging.style.left=x+'px';dragging.style.top=y+'px';dragging.style.right='auto';dragging.style.bottom='auto'});
document.addEventListener('mouseup',()=>{if(!dragging)return;let r=dragging.getBoundingClientRect();settings.positions[dragging.dataset.module]={x:Math.round(r.left),y:Math.round(r.top)};dragging.style.cursor='';dragging=null;save()});
renderToggles();apply();
