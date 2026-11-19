const app=document.getElementById('app'),grid=document.getElementById('grid'),search=document.getElementById('search');
let properties=[],filter='all';
const money=n=>new Intl.NumberFormat('nl-NL',{style:'currency',currency:'EUR',maximumFractionDigits:0}).format(Number(n||0));
function post(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});}
function render(){
 const q=search.value.toLowerCase();
 const list=properties.filter(p=>(filter==='all'||p.type===filter)&&(`${p.label} ${p.address}`.toLowerCase().includes(q)));
 grid.innerHTML='';
 if(!list.length){grid.innerHTML='<div class="empty">Geen woningen gevonden.</div>';return;}
 list.forEach(p=>{
  const card=document.createElement('article');card.className='card';
  const tag=p.type==='apartment'?'APPARTEMENT':'WONING';
  let actions='';
  if(p.hasKey) actions+=`<button data-action="enter" data-id="${p.id}">Betreed woning</button>`;
  else if(!p.owned){
   if(p.forSale)actions+=`<button data-action="buy" data-id="${p.id}">Kopen</button>`;
   if(p.forRent)actions+=`<button class="secondary" data-action="rent" data-id="${p.id}">Huren</button>`;
  } else actions+='<button class="secondary" disabled>Niet beschikbaar</button>';
  if(p.isOwner)actions+=`<button class="secondary" data-action="share" data-id="${p.id}">Sleutel delen</button>`;
  card.innerHTML=`<div class="cardtop"><span class="tag">${tag}</span><span class="status">${p.status}</span></div><h2>${p.label}</h2><div class="address">⌖ ${p.address}</div><div class="prices"><div class="price"><small>KOOPPRIJS</small><strong>${money(p.price)}</strong></div><div class="price"><small>HUUR / ${'PERIODE'}</small><strong>${money(p.rent)}</strong></div></div><div class="actions">${actions}</div>`;
  grid.appendChild(card);
 });
}
window.addEventListener('message',e=>{if(e.data.action==='open'){properties=e.data.properties||[];app.classList.remove('hidden');render();}});
document.getElementById('close').onclick=()=>{app.classList.add('hidden');post('close');};
search.addEventListener('input',render);
document.querySelectorAll('.filter').forEach(b=>b.onclick=()=>{document.querySelectorAll('.filter').forEach(x=>x.classList.remove('active'));b.classList.add('active');filter=b.dataset.filter;render();});
grid.addEventListener('click',e=>{
 const b=e.target.closest('button[data-action]');if(!b)return;
 const id=b.dataset.id,action=b.dataset.action;
 if(action==='share'){const target=prompt('Vul het server-ID in van de speler:');if(target)post('shareKey',{id,target:Number(target)});return;}
 if(action==='buy'||action==='rent'){if(!confirm(action==='buy'?'Wil je deze woning kopen?':'Wil je deze woning huren?'))return;post('purchase',{id,mode:action});}
 if(action==='enter')post('enter',{id});
});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!app.classList.contains('hidden')){app.classList.add('hidden');post('close');}});
