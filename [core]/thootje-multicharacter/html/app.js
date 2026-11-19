const app=document.getElementById('app'), list=document.getElementById('characterList'), createModal=document.getElementById('createModal'), spawnModal=document.getElementById('spawnModal');
let chars=[], maxChars=4, labels={}, spawns=[];
const post=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
function toast(msg){const el=document.getElementById('toast');el.textContent=msg;el.classList.add('show');setTimeout(()=>el.classList.remove('show'),2800)}
function render(){
 document.getElementById('slotCount').textContent=`${chars.length} / ${maxChars} PERSONAGES`;
 list.innerHTML='';
 chars.forEach(c=>{
  const card=document.createElement('article');card.className='character';
  const avatar=document.createElement('div');avatar.className='avatar';avatar.textContent=(c.firstname?.[0]||'?')+(c.lastname?.[0]||'');
  const name=document.createElement('div');name.className='char-name';name.textContent=`${c.firstname} ${c.lastname}`;
  const meta=document.createElement('div');meta.className='char-meta';meta.textContent=`${c.dateofbirth} · ${c.gender} · ${c.nationality}`;
  const actions=document.createElement('div');actions.className='char-actions';
  const play=document.createElement('button');play.className='small-btn play';play.textContent='SPELEN →';play.onclick=()=>post('select',{id:c.id});
  actions.append(play);
  const del=document.createElement('button');del.className='small-btn delete';del.textContent='×';del.title='Verwijderen';del.onclick=()=>{if(confirm(labels.confirmDelete||'Personage verwijderen?'))post('delete',{id:c.id})};
  actions.append(del);card.append(avatar,name,meta,actions);list.append(card);
 });
 if(chars.length<maxChars){
  const empty=document.createElement('div');empty.className='empty';empty.innerHTML='<div class="plus">＋</div><b>Een nieuw verhaal</b><span style="font-size:11px;margin-top:6px">Maak een nieuw personage aan</span>';
  const btn=document.createElement('button');btn.textContent='+ PERSONAGE AANMAKEN';btn.onclick=()=>createModal.classList.remove('hidden');empty.append(btn);list.append(empty);
 }
 if(chars.length===0){const p=document.createElement('p');p.className='muted';p.textContent=labels.noCharacters||'Maak je eerste personage aan.';list.prepend(p)}
}
window.addEventListener('message',e=>{
 const d=e.data||{};
 if(d.action==='open'){chars=d.characters||[];maxChars=d.maxCharacters||4;labels=d.labels||{};document.getElementById('title').textContent=labels.title||'THOOTJE CITY';document.getElementById('subtitle').textContent=labels.subtitle||'KIES JOUW VERHAAL';app.classList.remove('hidden');render()}
 if(d.action==='characters'){chars=d.characters||[];render()}
 if(d.action==='notify')toast(d.message||'Er is iets misgegaan.')
 if(d.action==='spawn'){spawns=d.spawns||[];document.getElementById('spawnList').innerHTML='';spawns.forEach((s,i)=>{const b=document.createElement('button');b.className='spawn-option';const title=document.createElement('b');title.textContent=s.label;const desc=document.createElement('small');desc.textContent=s.description||'';b.append(title,desc);b.onclick=()=>post('spawn',{index:i+1});document.getElementById('spawnList').append(b)});spawnModal.classList.remove('hidden')}
 if(d.action==='close'){app.classList.add('hidden');spawnModal.classList.add('hidden');createModal.classList.add('hidden')}
});
document.getElementById('createForm').addEventListener('submit',e=>{e.preventDefault();const data=Object.fromEntries(new FormData(e.target).entries());post('create',data);createModal.classList.add('hidden');e.target.reset()});
document.querySelectorAll('[data-close]').forEach(b=>b.addEventListener('click',()=>document.getElementById(b.dataset.close).classList.add('hidden')));
