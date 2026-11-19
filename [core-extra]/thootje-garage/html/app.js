let dataState=null,filter='all';
const app=document.getElementById('app');
const nui=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function status(v){if(v.impounded)return ['IN BESLAGNAME','impounded'];if(v.stored)return ['IN DE GARAGE',''];return ['BUITEN DE GARAGE','out'];}
function render(d){dataState=d;document.getElementById('garageName').textContent=d.garageLabel||'Garage';const all=d.vehicles||[];document.getElementById('counter').textContent=`${all.length} VOERTUIGEN`;document.getElementById('allCount').textContent=all.length;document.getElementById('storedCount').textContent=all.filter(v=>v.stored&&!v.impounded).length;document.getElementById('outCount').textContent=all.filter(v=>!v.stored&&!v.impounded).length;document.getElementById('impoundCount').textContent=all.filter(v=>v.impounded).length;
const term=document.getElementById('search').value.toLowerCase();let list=all.filter(v=>(v.label+' '+v.model+' '+v.plate+' '+(v.nickname||'')).toLowerCase().includes(term));
if(filter==='stored')list=list.filter(v=>v.stored&&!v.impounded);if(filter==='out')list=list.filter(v=>!v.stored&&!v.impounded);if(filter==='impounded')list=list.filter(v=>v.impounded);
document.getElementById('listTitle').textContent=({all:'Mijn voertuigen',stored:'Voertuigen in de garage',out:'Voertuigen buiten de garage',impounded:'In beslag genomen'})[filter];
const grid=document.getElementById('vehicleGrid');grid.innerHTML='';
if(!list.length){grid.innerHTML='<div class="empty">Geen voertuigen gevonden in deze categorie.</div>';return}
list.forEach(v=>{const [label,cls]=status(v);const fuel=Math.max(0,Math.min(100,Number(v.data?.fuel??100)));const engine=Math.max(0,Math.min(100,Number(v.data?.engine??1000)/10));const body=Math.max(0,Math.min(100,Number(v.data?.body??1000)/10));let card=document.createElement('article');card.className='vehicle';card.innerHTML=`<div class="veh-top"><div style="min-width:0"><div class="veh-name">${esc(v.nickname||v.label)}</div><div class="veh-model">${esc(v.label)} · ${esc(v.garageLabel)}</div></div><div class="plate">${esc(v.plate)}</div></div><span class="status ${cls}">${label}</span><div class="stats"><div class="metric"><span>Brandstof</span><b>${Math.round(fuel)}%</b><div class="bar"><i style="width:${fuel}%"></i></div></div><div class="metric"><span>Motor</span><b>${Math.round(engine)}%</b><div class="bar"><i style="width:${engine}%"></i></div></div><div class="metric"><span>Carrosserie</span><b>${Math.round(body)}%</b><div class="bar"><i style="width:${body}%"></i></div></div></div><div class="veh-actions" id="actions"></div>`;
const actions=card.querySelector('#actions');
if(v.impounded&&dataState.garageType==='impound'){let b=document.createElement('button');b.textContent=`Vrijgeven · €${Number(d.impoundFee).toLocaleString('nl-NL')}`;b.onclick=()=>nui('impound',{id:v.id});actions.append(b)}
else if(v.stored&&!v.impounded&&v.garage===d.garageId&&dataState.garageType!=='impound'){let b=document.createElement('button');b.textContent='Voertuig uitrijden';b.onclick=()=>nui('takeOut',{id:v.id});actions.append(b)}
else {let b=document.createElement('button');b.className='secondary';b.textContent=v.impounded?'Bekijk inbeslagname':(v.garage===d.garageId?'Al buiten':'Andere garage');b.disabled=true;actions.append(b)}
let rename=document.createElement('button');rename.className='secondary';rename.textContent='Naam wijzigen';rename.onclick=()=>{let n=prompt('Nieuwe voertuignaam:',v.nickname||v.label);if(n!==null)nui('rename',{id:v.id,nickname:n})};actions.append(rename);
grid.append(card);
});
}
window.addEventListener('message',e=>{if(e.data.action==='open'){app.classList.remove('hidden');render(e.data.data)}if(e.data.action==='update')render(e.data.data)});
document.getElementById('close').onclick=()=>{app.classList.add('hidden');nui('close')};
document.addEventListener('keydown',e=>{if(e.key==='Escape'){app.classList.add('hidden');nui('close')}});
document.getElementById('refresh').onclick=()=>nui('refresh');
document.getElementById('storeCurrent').onclick=()=>nui('store');
document.getElementById('search').addEventListener('input',()=>dataState&&render(dataState));
document.querySelectorAll('.side').forEach(b=>b.onclick=()=>{filter=b.dataset.filter;document.querySelectorAll('.side').forEach(x=>x.classList.remove('active'));b.classList.add('active');if(dataState)render(dataState)});
