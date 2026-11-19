const root=document.getElementById('inventory'), grid=document.getElementById('grid'), hotbar=document.getElementById('hotbar');
let state={items:[],slots:30,hotbarSlots:5,definitions:{},rarities:{}}, selected=null, dragFrom=null;
const post=(event,data={})=>fetch(`https://${GetParentResourceName()}/${event}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
const iconMap={water:'💧',bread:'🥖',sandwich:'🥪',bandage:'🩹',phone:'📱',radio:'📻',repairkit:'🧰',money:'💶'};
const bySlot=n=>state.items.find(i=>Number(i.slot)===n);
function fmtWeight(g){return g>=1000?(g/1000).toFixed(1)+' KG':g+' G'}
function totalWeight(){return state.items.reduce((a,i)=>a+(state.definitions[i.name]?.weight||0)*i.count,0)}
function updateWeight(){let w=state.weight??totalWeight(),max=state.maxWeight||30000;document.getElementById('weightText').textContent=`${fmtWeight(w)} / ${fmtWeight(max)}`;document.getElementById('weightBar').style.width=Math.min(100,w/max*100)+'%'}
function selectItem(item){selected=item;render();const def=item?state.definitions[item.name]||{}:{};document.getElementById('detailIcon').textContent=item?(iconMap[item.name]||'📦'):'?';document.getElementById('detailName').textContent=item?(def.label||item.label||item.name):'Selecteer een item';document.getElementById('detailDescription').textContent=item?(def.description||'Geen omschrijving beschikbaar.'):'Klik op een item om de details te bekijken.';document.getElementById('detailWeight').textContent=item?fmtWeight((def.weight||0)):'—';document.getElementById('detailCount').textContent=item?item.count:'—';document.getElementById('detailRarity').textContent=item?(state.rarities[def.rarity]||'Normaal'):'—';['use','drop','give'].forEach(id=>document.getElementById(id).disabled=!item);document.getElementById('use').disabled=!item||!def.usable}
function render(){
 grid.innerHTML='';
 const query=(document.getElementById('search').value||'').toLowerCase();
 for(let n=1;n<=state.slots;n++){
  const item=bySlot(n), def=item?(state.definitions[item.name]||{}):{};
  if(item&&query&&!(def.label||item.label||item.name).toLowerCase().includes(query)){const blank=document.createElement('div');blank.className='slot empty';blank.dataset.slot=n;grid.append(blank);continue}
  const el=document.createElement('div');el.className='slot'+(!item?' empty':'')+(selected&&item&&selected.slot===item.slot?' selected':'');el.dataset.slot=n;
  const num=document.createElement('span');num.className='slot-number';num.textContent=n;el.append(num);
  if(item){el.draggable=true;const ic=document.createElement('div');ic.className='item-icon';ic.textContent=iconMap[item.name]||'📦';const name=document.createElement('div');name.className='item-name';name.textContent=def.label||item.label||item.name;const count=document.createElement('span');count.className='count';count.textContent=item.count>1?item.count:'';const rarity=document.createElement('i');rarity.className='rarity '+(def.rarity||'common');el.append(ic,name,count,rarity);el.onclick=()=>selectItem(item);el.ondragstart=()=>{dragFrom=n};}
  el.ondragover=e=>{e.preventDefault();el.classList.add('dragover')};el.ondragleave=()=>el.classList.remove('dragover');el.ondrop=e=>{e.preventDefault();el.classList.remove('dragover');if(dragFrom&&dragFrom!==n)post('move',{from:dragFrom,to:n});dragFrom=null};
  grid.append(el);
 }
 document.getElementById('slotText').textContent=`${state.slots} SLOTS`;
 hotbar.innerHTML='';
 for(let n=1;n<=state.hotbarSlots;n++){const item=bySlot(n),el=document.createElement('div');el.className='hot-slot';const num=document.createElement('small');num.textContent=n;el.append(num);if(item){const ic=document.createElement('span');ic.textContent=iconMap[item.name]||'📦';el.append(ic)}hotbar.append(el)}
 updateWeight();
}
function applyData(data){state={...state,...data};if(selected){selected=bySlot(Number(selected.slot))||null}render();if(selected)selectItem(selected)}
window.addEventListener('message',e=>{const d=e.data||{};if(d.action==='open'){if(d.data)applyData(d.data);root.classList.remove('hidden')}if(d.action==='update')applyData(d.data||{});if(d.action==='close')root.classList.add('hidden');if(d.action==='notify')toast(d.message)});
function toast(msg){const el=document.getElementById('toast');el.textContent=msg;el.classList.add('show');setTimeout(()=>el.classList.remove('show'),2400)}
function close(){post('close');root.classList.add('hidden');selected=null}
document.getElementById('close').onclick=close;
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!root.classList.contains('hidden'))close()});
document.getElementById('search').addEventListener('input',render);
document.getElementById('use').onclick=()=>selected&&post('use',{slot:selected.slot});
document.getElementById('drop').onclick=()=>selected&&post('drop',{slot:selected.slot,count:1});
document.getElementById('give').onclick=()=>{if(!selected)return;const target=Number(prompt('Speler-ID aan wie je dit item wilt geven:'));if(target>0)post('give',{slot:selected.slot,target,count:1})};
function quickUse(n){const item=bySlot(n);if(item)post('use',{slot:n})}
document.addEventListener('keydown',e=>{if(root.classList.contains('hidden'))return;const n=Number(e.key);if(n>=1&&n<=state.hotbarSlots)quickUse(n)});
