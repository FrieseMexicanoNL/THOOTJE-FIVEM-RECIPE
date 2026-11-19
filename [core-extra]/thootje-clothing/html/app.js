const app=document.querySelector('#app'),modal=document.querySelector('#nameModal');let cats=[],current=null,mode='shop',outfits=[];
const post=(n,d={})=>fetch(`https://${GetParentResourceName()}/${n}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(d)});
window.addEventListener('message',e=>{let d=e.data;if(d.action==='open'){mode=d.mode||'shop';cats=d.categories||[];outfits=d.outfits||[];app.classList.remove('hidden');document.querySelector('#modeLabel').textContent=mode==='shop'?'KLEDINGWINKEL':'PERSOONLIJKE KLEDINGKAST';renderCats();renderOutfits()}if(d.action==='category'){current=d.category;setState(d.state);document.querySelector('#categoryTitle').textContent=current.label;document.querySelectorAll('.cat').forEach(x=>x.classList.toggle('active',x.dataset.id===current.id))}if(d.action==='state')setState(d.state);if(d.action==='outfits'){outfits=d.outfits||[];renderOutfits()}if(d.action==='close'){app.classList.add('hidden');modal.classList.add('hidden')}})
function renderCats(){document.querySelector('#categories').innerHTML=cats.map(c=>`<button class="cat" data-id="${c.id}"><span class="ico">${c.icon||'✦'}</span>${c.label}</button>`).join('');document.querySelectorAll('.cat').forEach(b=>b.onclick=()=>post('selectCategory',{id:b.dataset.id}))}
function setState(s){if(!s)return;let d=s.drawable??0,t=s.texture??0;['drawable','texture'].forEach((id,i)=>{let val=i?t:d,max=i?s.maxTexture:s.maxDrawable;document.querySelector('#'+id).value=val;document.querySelector('#'+id+'Range').value=val;document.querySelector('#'+id+'Range').max=max;});document.querySelector('#itemCounter').textContent=`${d} / ${s.maxDrawable} · variant ${t}/${s.maxTexture}`}
function change(){post('change',{drawable:Number(document.querySelector('#drawable').value),texture:Number(document.querySelector('#texture').value)})}
for(let id of ['drawable','texture']){document.querySelector('#'+id).addEventListener('change',change);document.querySelector('#'+id+'Range').addEventListener('input',e=>{document.querySelector('#'+id).value=e.target.value;change()});document.querySelector('#'+id+'Minus').onclick=()=>{document.querySelector('#'+id).value=Math.max(id==='drawable'&&current?.type==='prop'?-1:0,Number(document.querySelector('#'+id).value)-1);change()};document.querySelector('#'+id+'Plus').onclick=()=>{document.querySelector('#'+id).value=Number(document.querySelector('#'+id).value)+1;change()}}
function renderOutfits(){document.querySelector('#outfitCount').textContent=`${outfits.length} outfits`;document.querySelector('#outfitList').innerHTML=outfits.map(o=>`<div class="outfit-item">✦ ${escapeHtml(o.name)} <button onclick="loadFit(${o.id})">Aantrekken</button><button class="del" onclick="deleteFit(${o.id})">✕</button></div>`).join('')||'<span class="helper">Je hebt nog geen outfits opgeslagen.</span>'}
function escapeHtml(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
window.loadFit=id=>post('loadOutfit',{id});window.deleteFit=id=>post('deleteOutfit',{id});
document.querySelector('#close').onclick=()=>post('close');document.querySelector('#reset').onclick=()=>post('reset');document.querySelector('#rotateLeft').onclick=()=>post('rotate',{direction:-1});document.querySelector('#rotateRight').onclick=()=>post('rotate',{direction:1});
document.querySelector('#save').onclick=()=>{document.querySelector('#outfitName').value='';modal.classList.remove('hidden');document.querySelector('#outfitName').focus()};
document.querySelector('#cancelSave').onclick=()=>modal.classList.add('hidden');document.querySelector('#confirmSave').onclick=()=>{let name=document.querySelector('#outfitName').value.trim()||'Mijn outfit';post('saveOutfit',{name});modal.classList.add('hidden')};
document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(!modal.classList.contains('hidden'))modal.classList.add('hidden');else post('close')}});

// 2.0 quick links: extra studios are available as chat commands as well.
window.addEventListener('message',e=>{
  if(e.data?.action==='open'){
    const side=document.querySelector('aside');
    if(side && !document.querySelector('#studioLinks')){
      const box=document.createElement('div'); box.id='studioLinks'; box.className='studio-links';
      box.innerHTML='<div class="section-title">STYLE SERVICES</div><button class="cat" data-cmd="kapsalon">✂ Kapsalon</button><button class="cat" data-cmd="gezicht">◉ Gezichtsstudio</button><button class="cat" data-cmd="tattoos">✦ Tattoo studio</button><button class="cat" data-cmd="joboutfit">♜ Jobuniform</button>';
      side.insertBefore(box,side.querySelector('.aside-bottom'));
      box.querySelectorAll('[data-cmd]').forEach(b=>b.addEventListener('click',()=>post('close').then(()=>post('runCommand',{command:b.dataset.cmd}))));
    }
  }
});
