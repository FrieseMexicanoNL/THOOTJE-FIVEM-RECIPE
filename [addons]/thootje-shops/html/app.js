const app=document.getElementById('app'), list=document.getElementById('products'), search=document.getElementById('search');
let shop=null, tab='buy';
const icons={water:'◉',bread:'▰',sandwich:'▱',phone:'▣',radio:'⌁',repairkit:'⚒',bandage:'✚',fish:'♧',salmon:'♧',tuna:'♧'};
function nui(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});}
function render(){
 if(!shop)return;
 const items=(shop[tab]||[]).filter(p=>(p.label+' '+p.category+' '+p.item).toLowerCase().includes(search.value.toLowerCase()));
 list.innerHTML='';
 if(!items.length){list.innerHTML='<div class="empty">Geen producten gevonden in deze categorie.</div>';return;}
 items.forEach(p=>{
  const card=document.createElement('article');card.className='product';
  const icon=document.createElement('div');icon.className='product-icon';icon.textContent=icons[p.item]||'◆';
  const info=document.createElement('div');info.className='product-info';
  const title=document.createElement('b');title.textContent=p.label;
  const desc=document.createElement('small');desc.textContent=p.description||p.category;
  const price=document.createElement('div');price.className='price';price.textContent=`${shop.currency||'$'}${Number(p.price).toLocaleString('nl-NL')} / stuk`;
  info.append(title,desc,price);
  const button=document.createElement('button');button.className='buy';button.textContent=tab==='buy'?'KOPEN':'VERKOPEN';
  button.onclick=()=>{const amount=Math.max(1,Math.min(100,parseInt(prompt('Hoeveel wil je '+(tab==='buy'?'kopen':'verkopen')+'?', '1'),10)||1));nui(tab,{item:p.item,amount});toast('Transactie wordt verwerkt...');};
  card.append(icon,info,button);list.append(card);
 });
}
function toast(msg){const t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');setTimeout(()=>t.classList.remove('show'),1800);}
window.addEventListener('message',e=>{
 if(e.data.action==='open'){shop=e.data.shop;app.classList.remove('hidden');document.getElementById('shop-title').textContent=shop.label;document.getElementById('shop-subtitle').textContent=shop.subtitle;document.getElementById('currency').textContent=shop.currency||'$';tab=shop.buy.length?'buy':'sell';document.querySelectorAll('.tab').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));search.value='';render();}
});
document.querySelectorAll('.tab').forEach(b=>b.onclick=()=>{tab=b.dataset.tab;document.querySelectorAll('.tab').forEach(x=>x.classList.toggle('active',x===b));render();});
search.addEventListener('input',render);
document.getElementById('close').onclick=()=>{app.classList.add('hidden');nui('close');};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!app.classList.contains('hidden')){app.classList.add('hidden');nui('close');}});
