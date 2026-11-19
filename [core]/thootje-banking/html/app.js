const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
let account=null,history=[],pending=null,maxTransfer=250000,fee=0;
const fmt=n=>'€ '+Number(n||0).toLocaleString('nl-NL',{minimumFractionDigits:2,maximumFractionDigits:2});
function post(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)})}
function showToast(msg,kind='info'){let t=$('#toast');t.textContent=msg;t.className='show '+kind;clearTimeout(showToast.timer);showToast.timer=setTimeout(()=>t.className='',3200)}
function open(){ $('#app').classList.remove('hidden') }
function close(){ $('#app').classList.add('hidden');$('#confirm').classList.add('hidden');post('close') }
function setPage(name){$$('.page').forEach(p=>p.classList.toggle('hidden',p.id!==name));$$('.nav').forEach(b=>b.classList.toggle('active',b.dataset.page===name));let titles={overview:['PERSOONLIJK DASHBOARD','Goedendag 👋','Welkom bij jouw financiële overzicht.'],transfer:['BETALINGEN','Geld overboeken','Verstuur veilig een betaling naar een andere rekening.'],history:['REKENINGACTIVITEIT','Transacties','Bekijk al je inkomende en uitgaande betalingen.']};let t=titles[name];$('#pageEyebrow').textContent=t[0];$('#pageTitle').textContent=t[1];$('#pageSubtitle').textContent=t[2];}
function txMarkup(tx){let incoming=tx.type==='transfer_in'||tx.type==='deposit';let title=tx.description||({transfer_in:'Ontvangen overboeking',transfer_out:'Overboeking',deposit:'Bijschrijving',withdraw:'Afschrijving'}[tx.type]||'Transactie');let date=tx.createdAt?new Date(tx.createdAt).toLocaleString('nl-NL',{dateStyle:'medium',timeStyle:'short'}):'Recent';return `<div class="tx"><div class="tx-icon ${incoming?'in':'out'}">${incoming?'↙':'↗'}</div><div class="tx-info"><b>${esc(title)}</b><small>${date}${tx.counterpartyAccount?' · '+esc(tx.counterpartyAccount):''} · ${esc(tx.reference||'')}</small></div><div class="tx-amount ${incoming?'in':'out'}">${incoming?'+':'−'}${fmt(tx.amount)}</div></div>`}
function esc(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function render(){
 if(!account)return;
 $('#balance').textContent=fmt(account.balance);$('#accountNumber').textContent=account.number;$('#profileName').textContent=account.name||'Mijn rekening';$('#available').textContent=fmt(account.balance);
 let html=history.length?history.map(txMarkup).join(''):'<div class="empty">Nog geen transacties. Je rekening is klaar voor gebruik.</div>';
 $('#recent').innerHTML=history.slice(0,4).map(txMarkup).join('')||'<div class="empty">Nog geen recente activiteit.</div>';$('#allTransactions').innerHTML=html;
}
window.addEventListener('message',e=>{let m=e.data;if(m.action==='show')open();if(m.action==='hide')$('#app').classList.add('hidden');if(m.action==='data'){account=m.payload.account;history=m.payload.history||[];maxTransfer=m.payload.maxTransfer||250000;fee=m.payload.transferFee||0;$('#pageTitle').textContent='Goedendag 👋';render();open()}if(m.action==='refresh'){account=m.account;history=m.history||[];render()}if(m.action==='toast')showToast(m.message,m.kind)});
$$('.nav').forEach(b=>b.onclick=()=>setPage(b.dataset.page));$$('[data-goto]').forEach(b=>b.onclick=()=>setPage(b.dataset.goto));
$('#close').onclick=close;document.addEventListener('keydown',e=>{if(e.key==='Escape')close()});
$('#copy').onclick=async()=>{try{await navigator.clipboard.writeText(account.number);showToast('Rekeningnummer gekopieerd.','success')}catch(e){showToast('Kopiëren is niet beschikbaar.','error')}};
$('#rename').onclick=()=>{let name=prompt('Nieuwe naam voor je rekening:',account?.name||'Mijn betaalrekening');if(name)post('rename',{name})};
$('#transferForm').onsubmit=e=>{e.preventDefault();let number=$('#target').value.trim().toUpperCase(),amount=Math.floor(Number($('#amount').value)),description=$('#description').value.trim();if(!number||amount<1||amount>maxTransfer){showToast('Controleer het rekeningnummer en bedrag.','error');return}if(amount+fee>Number(account.balance)){showToast('Je hebt onvoldoende saldo inclusief eventuele kosten.','error');return}pending={accountNumber:number,amount,description};$('#confirmAccount').textContent=number;$('#confirmAmount').textContent=fmt(amount)+(fee?` + ${fmt(fee)} kosten`: '');$('#confirmDescription').textContent=description||'Geen omschrijving';$('#confirm').classList.remove('hidden')};
$('#cancelConfirm').onclick=()=>$('#confirm').classList.add('hidden');$('#sendConfirm').onclick=()=>{if(!pending)return;post('transfer',pending);$('#confirm').classList.add('hidden');$('#transferForm').reset();pending=null;setPage('overview');showToast('Je overboeking wordt verwerkt.','info')};
</script>
