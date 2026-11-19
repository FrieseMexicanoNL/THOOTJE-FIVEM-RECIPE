const $=id=>document.getElementById(id);
let profile={},contacts=[],messages=[],notes=[],wallpapers={},currentApp='home',currentNumber='',incoming=null,callState=null,unread=0;
const post=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)});
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function showHome(){ $('appscreen').classList.add('hidden');$('home').classList.remove('hidden');currentApp='home';}
function showApp(app){currentApp=app;$('home').classList.add('hidden');$('appscreen').classList.remove('hidden');$('appTitle').textContent=({phone:'Telefoon',messages:'Berichten',contacts:'Contacten',settings:'Instellingen',notes:'Notities'})[app]||app;$('appSub').textContent='THOOTJE MOBILE';renderApp();}
function renderApp(){
 const c=$('content');
 if(currentApp==='contacts'){
  c.innerHTML=`<div class="sectiontitle">CONTACTEN</div><input id="cname" class="field" placeholder="Naam"><input id="cnumber" class="field" placeholder="Telefoonnummer (06...)"><button id="addContact" class="primary">＋ Contact toevoegen</button><div class="sectiontitle" style="margin-top:20px">OPGESLAGEN CONTACTEN</div>${contacts.map(x=>`<div class="row"><div><strong>${esc(x.name)}</strong><small>${esc(x.number)}</small></div><button class="secondary" data-sms="${esc(x.number)}">SMS</button><button class="danger" data-del="${x.id}">×</button></div>`).join('')||'<div class="empty">Je hebt nog geen contacten.</div>'}`;
  $('addContact').onclick=()=>{if($('cname').value&&$('cnumber').value)post('addContact',{name:$('cname').value,number:$('cnumber').value});};
  c.querySelectorAll('[data-del]').forEach(b=>b.onclick=()=>post('deleteContact',{id:Number(b.dataset.del)}));
  c.querySelectorAll('[data-sms]').forEach(b=>b.onclick=()=>openConversation(b.dataset.sms));
 }else if(currentApp==='phone'){
  c.innerHTML=`<div class="sectiontitle">NUMMER KIEZEN</div><div id="dialdisplay" class="dialdisplay">${esc(currentNumber||'Voer nummer in')}</div><div class="keypad">${['1','2','3','4','5','6','7','8','9','*','0','#'].map(n=>`<button data-digit="${n}">${n}</button>`).join('')}</div><button id="dialBack" class="secondary" style="display:block;margin:10px auto">⌫ Wissen</button><button id="callNow" class="callbtn">☎</button><div class="sectiontitle">SNELKIEZEN / CONTACTEN</div>${contacts.slice(0,5).map(x=>`<div class="row"><div><strong>${esc(x.name)}</strong><small>${esc(x.number)}</small></div><button class="primary" data-call="${esc(x.number)}">Bel</button></div>`).join('')}`;
  c.querySelectorAll('[data-digit]').forEach(b=>b.onclick=()=>{currentNumber+=b.dataset.digit;$('dialdisplay').textContent=currentNumber;});
  $('dialBack').onclick=()=>{currentNumber=currentNumber.slice(0,-1);$('dialdisplay').textContent=currentNumber||'Voer nummer in';};
  $('callNow').onclick=()=>{if(currentNumber)post('startCall',{number:currentNumber});};
  c.querySelectorAll('[data-call]').forEach(b=>b.onclick=()=>post('startCall',{number:b.dataset.call}));
 }else if(currentApp==='messages'){
  const grouped={};messages.forEach(m=>{const n=m.other_number;grouped[n]=grouped[n]||[];grouped[n].push(m);});
  c.innerHTML=`<div class="sectiontitle">RECENTE GESPREKKEN</div>${Object.keys(grouped).map(n=>{const m=grouped[n][0];return `<div class="row" data-thread="${esc(n)}"><div><strong>${esc(contactName(n))}</strong><small>${esc(m.message)}</small></div><button class="secondary">Openen</button></div>`;}).join('')||'<div class="empty">Nog geen berichten. Start een nieuw gesprek.</div>'}<div style="margin-top:14px"><input id="newNumber" class="field" placeholder="Nieuw nummer (06...)"><button id="newChat" class="primary">Nieuw bericht</button></div>`;
  c.querySelectorAll('[data-thread]').forEach(b=>b.onclick=()=>openConversation(b.dataset.thread));
  $('newChat').onclick=()=>{if($('newNumber').value)openConversation($('newNumber').value);};
 }else if(currentApp==='settings'){
  c.innerHTML=`<div class="sectiontitle">MIJN TELEFOON</div><div class="row"><div><strong>Telefoonnummer</strong><small>${esc(profile.number||'')}</small></div><span>SIM</span></div><div class="sectiontitle">ACHTERGROND KIEZEN</div><div class="wallchoice">${Object.keys(wallpapers).map(w=>`<button data-wall="${w}" title="${esc(wallpapers[w])}" class="${profile.wallpaper===w?'selected':''}" style="background:${wallStyle(w)}"></button>`).join('')}</div><p style="color:#8198ab;font-size:9px">Je gekozen achtergrond wordt opgeslagen op je personage.</p><button id="refresh" class="secondary">Gegevens vernieuwen</button>`;
  c.querySelectorAll('[data-wall]').forEach(b=>b.onclick=()=>post('wallpaper',{wallpaper:b.dataset.wall}));
  $('refresh').onclick=()=>post('refresh');
 }else if(currentApp==='notes'){
  c.innerHTML=`<div class="sectiontitle">MIJN NOTITIES</div><button id="newNote" class="primary">＋ Nieuwe notitie</button><div style="margin-top:15px">${notes.map(n=>`<div class="row"><div><strong>${esc(n.title)}</strong><small>${esc((n.body||'').slice(0,65))}</small></div><button class="secondary" data-edit="${n.id}">Open</button><button class="danger" data-note-del="${n.id}">×</button></div>`).join('')||'<div class="empty">Je hebt nog geen notities.</div>'}</div>`;
  $('newNote').onclick=()=>editNote(null);
  c.querySelectorAll('[data-edit]').forEach(b=>b.onclick=()=>editNote(notes.find(n=>n.id==b.dataset.edit)));
  c.querySelectorAll('[data-note-del]').forEach(b=>b.onclick=()=>post('deleteNote',{id:Number(b.dataset.noteDel)}));
 }
}
function contactName(number){const x=contacts.find(c=>c.number===number);return x?x.name:number;}
function wallStyle(w){return ({aurora:'linear-gradient(140deg,#38b9ad,#203c75)',midnight:'linear-gradient(140deg,#18213b,#050812)',ocean:'linear-gradient(140deg,#247f9b,#142b5c)',sunset:'linear-gradient(140deg,#f18a64,#693a72)'})[w];}
function openConversation(number){
 currentApp='conversation';currentNumber=number;$('home').classList.add('hidden');$('appscreen').classList.remove('hidden');$('appTitle').textContent=contactName(number);$('appSub').textContent=number;
 const list=messages.filter(m=>m.other_number===number).slice().reverse();
 $('content').innerHTML=`<div id="chat">${list.map(m=>`<div class="chatbubble ${m.direction==='out'?'out':''}">${esc(m.message)}</div><div class="chatmeta ${m.direction==='out'?'out':''}">${m.direction==='out'?'Verzonden':'Ontvangen'}</div>`).join('')}</div><div class="compose"><input id="smsText" class="field" placeholder="Typ een bericht..." maxlength="500"><button id="sendSms" class="primary">➤</button></div>`;
 $('sendSms').onclick=sendSms;$('smsText').addEventListener('keydown',e=>{if(e.key==='Enter')sendSms();});
}
function sendSms(){const message=$('smsText').value.trim();if(message){post('sendMessage',{number:currentNumber,message});$('smsText').value='';}}
function editNote(n){
 currentApp='noteedit';$('appTitle').textContent=n?'Notitie bewerken':'Nieuwe notitie';
 $('content').innerHTML=`<input id="noteTitle" class="field" placeholder="Titel" value="${esc(n?.title||'')}"><textarea id="noteBody" class="field notearea" placeholder="Schrijf je notitie...">${esc(n?.body||'')}</textarea><button id="saveNote" class="primary">Opslaan</button>`;
 $('saveNote').onclick=()=>post('saveNote',{id:n?.id||0,title:$('noteTitle').value,body:$('noteBody').value});
}
function showCall(data,incomingCall){
 incoming=data.callId;$('callOverlay').classList.remove('hidden');$('callName').textContent=data.name||data.number;$('callNumber').textContent=data.number||'';
 $('callState').textContent=incomingCall?'INKOMEND GESPREK':'BELLEN...';
 $('answer').classList.toggle('hidden',!incomingCall);$('decline').classList.remove('hidden');$('hangup').classList.add('hidden');
}
$('answer').onclick=()=>{post('answerCall',{callId:incoming});$('callState').textContent='VERBINDEN...';};
$('decline').onclick=()=>{post('declineCall',{callId:incoming});$('callOverlay').classList.add('hidden');};
$('hangup').onclick=()=>post('hangup');
window.addEventListener('message',e=>{
 const d=e.data;
 if(d.action==='open'){
  profile=d.data.profile||{};contacts=d.data.contacts||[];messages=d.data.messages||[];notes=d.data.notes||[];wallpapers=d.data.wallpapers||{};
  $('myNumber').textContent=profile.number||'';$('date').textContent=new Date().toLocaleDateString('nl-NL',{weekday:'long',day:'numeric',month:'long'});
  $('phone').classList.remove('hidden');$('home').classList.remove('hidden');$('appscreen').classList.add('hidden');
  $('device').className='device '+(profile.wallpaper||'aurora');
 }
 if(d.action==='data'){if(d.data.contacts)contacts=d.data.contacts;if(d.data.messages)messages=d.data.messages;if(d.data.notes)notes=d.data.notes;if(currentApp==='conversation')openConversation(currentNumber);else renderApp();}
 if(d.action==='newMessage'){messages.unshift({other_number:d.data.sender,message:d.data.message,direction:'in',sender_number:d.data.sender,receiver_number:profile.number});unread++;$('smsBadge').textContent=unread;$('smsBadge').classList.remove('hidden');if(currentApp==='conversation'&&currentNumber===d.data.sender)openConversation(currentNumber);else if(currentApp==='messages')renderApp();}
 if(d.action==='incomingCall')showCall(d.data,true);
 if(d.action==='outgoingCall')showCall(d.data,false);
 if(d.action==='callConnected'){$('callState').textContent='IN GESPREK';$('answer').classList.add('hidden');$('decline').classList.add('hidden');$('hangup').classList.remove('hidden');}
 if(d.action==='callEnded'){$('callOverlay').classList.add('hidden');incoming=null;}
 if(d.action==='wallpaper'){profile.wallpaper=d.wallpaper;$('device').className='device '+d.wallpaper;renderApp();}
});
document.querySelectorAll('[data-app]').forEach(b=>b.onclick=()=>showApp(b.dataset.app));
$('back').onclick=()=>{if(currentApp==='conversation'){showApp('messages');return;}if(currentApp==='noteedit'){showApp('notes');return;}showHome();};
$('appClose').onclick=showHome;
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('phone').classList.contains('hidden')){if(!$('callOverlay').classList.contains('hidden'))return;$('phone').classList.add('hidden');post('close');}});
