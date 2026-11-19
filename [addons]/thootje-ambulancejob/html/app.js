const app=document.getElementById('app'),content=document.getElementById('content');
let state={calls:[],roster:[],treatments:[],openCalls:0},nearby=[],page='dashboard',vehicles=[],garageStation=1;
const nui=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=v=>'$'+Number(v||0).toLocaleString('nl-NL');
function setPage(p){page=p;document.querySelectorAll('.nav').forEach(b=>b.classList.toggle('active',b.dataset.page===p));document.getElementById('page-title').textContent=({dashboard:'Overzicht',calls:'112-meldingen',patients:'Patiënten',treatments:'Behandelingen',billing:'Facturatie',garage:'Dienstgarage'})[p]||'Overzicht';render()}
function render(){
 document.getElementById('call-count').textContent=state.openCalls||0;
 if(page==='dashboard'){
  const on=(state.roster||[]).filter(x=>x.onduty).length;
  content.innerHTML=`<div class="cards"><div class="stat"><small>AMBULANCEPERSONEEL IN DIENST</small><b class="accent">${on}</b></div><div class="stat"><small>OPEN 112-MELDINGEN</small><b>${state.openCalls||0}</b></div><div class="stat"><small>ACTIEVE EENHEDEN</small><b>${on}</b></div><div class="stat"><small>BEHANDELINGEN VASTGELEGD</small><b>${(state.treatments||[]).length}</b></div></div><div class="grid"><div class="panel"><h3>Actuele noodmeldingen</h3>${(state.calls||[]).slice(0,5).map(callCard).join('')||'<div class="empty">Geen openstaande meldingen.</div>'}</div><div class="panel"><h3>Ambulancepersoneel</h3>${(state.roster||[]).map(p=>`<div class="row"><span>${esc(p.name)} <small>· ${esc(p.gradeLabel)}</small></span><span class="pill ${p.onduty?'':'off'}">${p.onduty?'IN DIENST':'UIT DIENST'}</span></div>`).join('')||'<div class="empty">Geen personeelsgegevens.</div>'}</div></div>`;
 }else if(page==='calls'){
  content.innerHTML=`<div class="panel"><h3>Dispatch / 112-meldingen</h3>${(state.calls||[]).map(callCard).join('')||'<div class="empty">Er staan geen meldingen open.</div>'}</div>`;
  bindCallButtons();
 }else if(page==='patients'){
  content.innerHTML=`<div class="panel"><div class="row"><h3>Spelers in de omgeving</h3><button class="action" id="scan">OMGEVING VERVERSEN</button></div><p class="muted">Behandelopties verbruiken medische items uit jouw THOOTJE-INVENTORY.</p>${nearby.map(p=>`<div class="patient"><div><b>${esc(p.name)} (#${p.id})</b><small>${p.distance} meter · gezondheid ${p.health}${p.down?' · MOGELIJK NEER':''}</small></div><div class="call-actions"><button class="action good" data-treat="revive" data-id="${p.id}">REANIMEREN</button><button class="action" data-treat="heal" data-id="${p.id}">VERBAND</button><button class="action" data-treat="stabilize" data-id="${p.id}">STABILISEER</button></div></div>`).join('')||'<div class="empty">Geen spelers binnen 15 meter gevonden.</div>'}</div>`;
  document.getElementById('scan').onclick=()=>nui('nearby');
  content.querySelectorAll('[data-treat]').forEach(b=>b.onclick=()=>nui('treat',{target:Number(b.dataset.id),treatment:b.dataset.treat}));
 }else if(page==='treatments'){
  content.innerHTML=`<div class="panel"><h3>Medische handelingen</h3><div class="treatment-grid"><div class="treat-card"><b>✚ Reanimatie</b><p>Reanimeer een neergehaalde patiënt. Vereist een medikit.</p><button class="action" data-go="patients">OPEN PATIËNTEN</button></div><div class="treat-card"><b>＋ Verband aanleggen</b><p>Herstel gezondheid bij een gewonde patiënt. Vereist verband.</p><button class="action" data-go="patients">OPEN PATIËNTEN</button></div><div class="treat-card"><b>♡ Stabiliseren</b><p>Stabiliseer een patiënt met een EHBO-set.</p><button class="action" data-go="patients">OPEN PATIËNTEN</button></div></div></div><div class="panel"><h3>Recente behandelregistraties</h3>${(state.treatments||[]).map(t=>`<div class="row"><span>${esc(t.treatment)} <small>· ${esc(t.patient_name)} · door ${esc(t.medic_name)}</small></span><small>${esc(t.created_at)}</small></div>`).join('')||'<div class="empty">Nog geen behandelingen geregistreerd.</div>'}</div>`;
  content.querySelectorAll('[data-go]').forEach(b=>b.onclick=()=>setPage(b.dataset.go));
 }else if(page==='billing'){
  content.innerHTML=`<div class="panel"><h3>Factuur versturen via THOOTJE-BILLING</h3><p class="muted">Maak een normale factuur aan voor een patiënt. De patiënt ontvangt deze in THOOTJE-BILLING. Er wordt geen persoonlijke uitbetaling aan de medewerker gedaan.</p><div class="form"><div class="field"><label>SERVER-ID PATIËNT</label><input id="bill-target" type="number" min="1" placeholder="Bijv. 12"></div><div class="field"><label>BEDRAG</label><input id="bill-amount" type="number" min="1" max="25000" placeholder="Bijv. 350"></div><div class="field full"><label>OMSCHRIJVING</label><input id="bill-reason" maxlength="90" placeholder="Bijv. Ambulancevervoer en behandeling"></div><div class="field full"><button class="action" id="send-bill">FACTUUR AANMAKEN</button></div></div></div>`;
  document.getElementById('send-bill').onclick=()=>{const target=Number(document.getElementById('bill-target').value),amount=Number(document.getElementById('bill-amount').value),reason=document.getElementById('bill-reason').value;if(target&&amount&&reason)nui('invoice',{target,amount,reason})};
 }else if(page==='garage'){
  content.innerHTML=`<div class="panel"><h3>Ambulancevoertuigen</h3><p class="muted">Kies een voertuig. Je moet bij een ambulancepostgarage staan.</p><div class="vehicle-grid">${vehicles.map((v,i)=>`<div class="vehicle"><b>🚑 ${esc(v.label)}</b><small>Model: ${esc(v.model)} · Vanaf rang ${v.minGrade}</small><button class="action" data-vehicle="${i+1}">VOERTUIG UITGEVEN</button></div>`).join('')||'<div class="empty">Open de garage bij een ambulancepost om de voertuigenlijst te laden.</div>'}</div></div>`;
  content.querySelectorAll('[data-vehicle]').forEach(b=>b.onclick=()=>nui('spawnVehicle',{index:Number(b.dataset.vehicle),station:garageStation}));
 }
}
function callCard(c){return `<div class="call"><div class="call-main"><b>#${c.id} · ${esc(c.call_type)} · ${esc(c.caller_name||'Onbekend')}</b><small>${esc(c.message)} · ${esc(c.created_at||'')}</small><small>Status: ${esc(c.status)} ${c.assigned_name?'· Eenheid: '+esc(c.assigned_name):''}</small></div><div class="call-actions">${c.status==='open'?`<button class="action good" data-accept="${c.id}">ACCEPTEREN</button>`:''}${c.status==='assigned'&&c.assigned_name?`<button class="action" data-complete="${c.id}">AFRONDEN</button>`:''}</div></div>`}
function bindCallButtons(){content.querySelectorAll('[data-accept]').forEach(b=>b.onclick=()=>nui('acceptCall',{id:Number(b.dataset.accept)}));content.querySelectorAll('[data-complete]').forEach(b=>b.onclick=()=>nui('completeCall',{id:Number(b.dataset.complete)}))}
document.querySelectorAll('.nav').forEach(b=>b.onclick=()=>{if(b.dataset.page==='patients')nui('nearby');if(b.dataset.page==='garage')nui('garage');setPage(b.dataset.page)});
document.getElementById('close').onclick=()=>{app.classList.add('hidden');nui('close')};
document.getElementById('refresh').onclick=()=>nui('refresh');
document.getElementById('panic').onclick=()=>nui('panic');
window.addEventListener('message',e=>{
 const d=e.data||{};
 if(d.action==='open'){state=d.data||state;nearby=d.nearby||[];app.classList.remove('hidden');setPage('dashboard')}
 if(d.action==='update'){state=d.data||state;render()}
 if(d.action==='nearby'){nearby=d.nearby||[];if(page==='patients')render()}
 if(d.action==='garage'){vehicles=d.vehicles||[];garageStation=d.station||1;if(page==='garage')render()}
 if(d.action==='close')app.classList.add('hidden');
});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!app.classList.contains('hidden')){app.classList.add('hidden');nui('close')}});
