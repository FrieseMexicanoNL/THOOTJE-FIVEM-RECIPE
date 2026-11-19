const hud=document.getElementById('hud'), inv=document.getElementById('inventory'), items=document.getElementById('items');
function money(v){return '€'+Number(v||0).toLocaleString('nl-NL')}
window.addEventListener('message',e=>{
 const d=e.data||{};
 if(d.action==='player'&&d.data){const p=d.data;document.getElementById('playerName').textContent=p.name||'Speler';document.getElementById('job').textContent=(p.job?.label||'Werkloos')+' · '+(p.job?.gradeLabel||'');document.getElementById('cash').textContent=money(p.accounts?.cash);document.getElementById('bank').textContent=money(p.accounts?.bank)}
 if(d.action==='inventory'){items.innerHTML='';(d.items||[]).forEach(it=>{const el=document.createElement('div');el.className='slot';const title=document.createElement('b');title.textContent=it.label||it.name;const count=document.createElement('span');count.textContent='Aantal: '+it.count;el.append(title,count);items.append(el)});inv.classList.remove('hidden')}
 if(d.action==='close')inv.classList.add('hidden');
 if(d.action==='toggleHud')hud.classList.toggle('hidden');
});
function close(){fetch(`https://${GetParentResourceName()}/close`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});inv.classList.add('hidden')}
document.getElementById('close').addEventListener('click',close);
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!inv.classList.contains('hidden'))close()});
