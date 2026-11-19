const app=document.getElementById('app'),content=document.getElementById('content');let state={reports:[],fines:[],police:[]},page='dashboard',searchResults=[],inventoryTarget=null;
const nui=(n,d={})=>fetch(`https://${GetParentResourceName()}/${n}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)});
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function setPage(p){page=p;document.querySelectorAll('.nav').forEach(b=>b.classList.toggle('active',b.dataset.page===p));document.getElementById('page-title').textContent=({dashboard:'Overzicht',players:'Personen zoeken',reports:'Rapportages',create:'Rapport maken',fines:'Boetes'})[p];render();}
function render(){
 if(page==='dashboard'){
  const on=(state.police||[]).filter(p=>p.onduty).length;
  content.innerHTML=`<div class="cards"><div class="stat"><small>AGENTEN IN DIENST</small><b>${on}</b></div><div class="stat"><small>RAPPORTAGES</small><b>${(state.reports||[]).length}</b></div><div class="stat"><small>OPEN BOETES</small><b>${(state.fines||[]).filter(f=>f.status==='open').length}</b></div></div><div class="section"><h3>Beschikbare eenheden</h3>${(state.police||[]).map(p=>`<div class="row"><span>${esc(p.name)} <small>· ${esc(p.grade)}</small></span><span class="pill ${p.onduty?'':'off'}">${p.onduty?'IN DIENST':'BUITEN DIENST'}</span></div>`).join('')||'<div class="empty">Geen politiegegevens beschikbaar.</div>'}</div><div class="section"><h3>Recente rapportages</h3>${(state.reports||[]).slice(0,5).map(r=>`<div class="row"><span>${esc(r.title)} <small>· ${esc(r.officer_name)}</small></span><small>#${r.id}</small></div>`).join('')||'<div class="empty">Nog geen rapportages.</div>'}</div>`;
 }else if(page==='players'){
  content.innerHTML=`<div class="section"><h3>Zoeken in online spelers</h3><div class="searchbar"><input id="query" placeholder="Naam of server-ID"><button class="action" id="find">ZOEKEN</button></div><div id="results">${resultHtml()}</div></div>`;
  document.getElementById('find').onclick=()=>nui('searchPlayer',{query:document.getElementById('query').value});
  document.getElementById('query').addEventListener('keydown',e=>{if(e.key==='Enter')document.getElementById('find').click()});
 }else if(page==='create'){
  content.innerHTML=`<div class="section"><h3>Nieuw politie-rapport</h3><div class="form"><div class="field"><label>Naam verdachte (optioneel)</label><input id="suspect" placeholder="Naam of beschrijving"></div><div class="field"><label>Titel rapport</label><input id="title" maxlength="80" placeholder="Bijv. Verkeersincident"></div><div class="field full"><label>Rapportage / bevindingen</label><textarea id="description" maxlength="2000" placeholder="Beschrijf de situatie, betrokkenen en bevindingen..."></textarea></div><div class="field full"><button class="action" id="save">RAPPORT OPSLAAN</button></div></div></div>`;
  document.getElementById('save').onclick=()=>nui('createReport',{suspect:document.getElementById('suspect').value,title:document.getElementById('title').value,description:document.getElementById('description').value});
 }else if(page==='reports'){
  content.innerHTML=`<div class="section"><h3>Laatste rapportages</h3>${(state.reports||[]).map(r=>`<div class="result"><div><b>${esc(r.title)}</b><small>${esc(r.suspect_name||'Geen verdachte')} · ${esc(r.officer_name)} · ${esc(r.created_at)}</small><small>${esc(r.description)}</small></div><span class="pill">#${r.id}</span></div>`).join('')||'<div class="empty">Geen rapportages gevonden.</div>'}</div>`;
 }else if(page==='fines'){
  content.innerHTML=`<div class="section"><h3>Geregistreerde boetes</h3>${(state.fines||[]).map(f=>`<div class="result"><div><b>${esc(f.suspect_name)} <small>· door ${esc(f.officer_name)}</small></b><small>${esc(f.reason)}</small></div><div class="fine">$${Number(f.amount).toLocaleString('nl-NL')}<small>${esc(f.status)}</small></div></div>`).join('')||'<div class="empty">Geen boetes geregistreerd.</div>'}</div>`;
 }
}
function resultHtml(){if(!searchResults.length)return '<div class="empty">Zoek op naam of server-ID.</div>';return searchResults.map(p=>`<div class="result"><div><b>${esc(p.name)} (#${p.id})</b><small>${esc(p.job)} · rang ${p.grade} · ${p.onduty?'in dienst':'niet in dienst'}</small></div><div class="actions"><button class="action" data-search="${p.id}">FOUILLEER</button><button class="action" data-fine="${p.id}">BOETE</button></div></div>`).join('')}
document.querySelectorAll('.nav').forEach(b=>b.onclick=()=>setPage(b.dataset.page));
document.getElementById('close').onclick=()=>{app.classList.add('hidden');nui('close')};
document.getElementById('refresh').onclick=()=>nui('refresh');

function bindResultButtons(el){
 el.querySelectorAll('[data-fine]').forEach(b=>b.onclick=()=>{const amount=prompt('Boetebedrag:');const reason=prompt('Reden van de boete:');if(amount&&reason)nui('fine',{target:Number(b.dataset.fine),amount:Number(amount),reason})});
 el.querySelectorAll('[data-search]').forEach(b=>b.onclick=()=>nui('inspectPlayer',{target:Number(b.dataset.search)}));
}
window.addEventListener('message',e=>{
 if(e.data.action==='open'){state=e.data.data||state;app.classList.remove('hidden');setPage('dashboard')}
 if(e.data.action==='update'){state=e.data.data||state;render()}
 if(e.data.action==='searchResults'){searchResults=e.data.results||[];const el=document.getElementById('results');if(el){el.innerHTML=resultHtml();bindResultButtons(el)}}
 if(e.data.action==='showInventory'){inventoryTarget=Number(e.data.target);const el=document.getElementById('results');if(!el)return;const items=e.data.items||[];el.innerHTML=`<div class="section"><h3>Inventaris: ${esc(e.data.targetName)} (#${inventoryTarget})</h3><p class="muted">Items innemen kan alleen als de speler geboeid en dichtbij is.</p>${items.length?items.map(i=>`<div class="result"><div><b>${esc(i.label)}</b><small>${esc(i.name)} · aantal: ${i.count}</small></div><button class="action" data-take="${esc(i.name)}" data-count="${i.count}">NEEM IN</button></div>`).join(''):'<div class="empty">Deze speler heeft geen items.</div>'}<button class="action secondary" id="back-search">TERUG NAAR ZOEKRESULTATEN</button></div>`;el.querySelectorAll('[data-take]').forEach(b=>b.onclick=()=>{const max=Number(b.dataset.count);const amount=Number(prompt(`Hoeveel wil je innemen? (1-${max})`,String(max)));if(Number.isInteger(amount)&&amount>0&&amount<=max)nui('confiscateItem',{target:inventoryTarget,name:b.dataset.take,amount})});document.getElementById('back-search')?.addEventListener('click',()=>{el.innerHTML=resultHtml();bindResultButtons(el)})}
 if(e.data.action==='close')app.classList.add('hidden');
});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!app.classList.contains('hidden')){app.classList.add('hidden');nui('close')}});
