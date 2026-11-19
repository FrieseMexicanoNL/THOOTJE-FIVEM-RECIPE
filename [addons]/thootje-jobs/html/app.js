const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
let jobs=[],current=null,selected=null,filter='all';
const icons={taxi:'↗',mechanic:'⚙',garbage:'♻',trucker:'▰',bus:'▣',fisherman:'♧',farmer:'❋',police:'⬡',ambulance:'✚',fire:'♨',government:'⌂',lawyer:'⚖'};
function post(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)})}
function toast(msg,kind){let t=$('#toast');t.textContent=msg;t.className='show '+(kind||'');clearTimeout(toast.timer);toast.timer=setTimeout(()=>t.className='',3000)}
function close(){post('close');$('#app').classList.add('hidden');$('#detail').classList.add('hidden')}
function renderCurrent(){
 if(!current)return;$('#currentJob').textContent=current.label||'Werkloos';$('#currentGrade').textContent=(current.gradeLabel||'Burger')+' · '+(current.onduty?'In dienst':'Uit dienst');$('#duty').classList.toggle('hidden',current.name==='unemployed');
}
function renderJobs(){
 let q=$('#search').value.toLowerCase();
 let list=jobs.filter(j=>(filter==='all'||j.category===filter)&&(`${j.label} ${j.description}`.toLowerCase().includes(q)));
 $('#count').textContent=list.length+' functies beschikbaar';
 $('#jobs').innerHTML=list.map(j=>`<div class="job-card" data-job="${j.name}"><div class="job-icon">${icons[j.name]||'✦'}</div><div class="job-info"><b>${j.label}</b><small>${j.description||''}</small></div><span class="job-tag ${j.category==='overheid'?'gov':''}">${j.category==='overheid'?'OVERHEID':'CIVIEL'}</span><span class="arrow">›</span></div>`).join('')||'<div class="empty">Geen banen gevonden.</div>';
 $$('.job-card').forEach(el=>el.onclick=()=>showDetail(jobs.find(j=>j.name===el.dataset.job)));
}
function showDetail(job){
 selected=job;if(!job)return;
 $('#detailCategory').textContent=job.category==='overheid'?'OVERHEIDSDIENST':'CIVIELE FUNCTIE';$('#detailName').textContent=job.label;$('#detailDescription').textContent=job.description;
 $('#grades').innerHTML=(job.grades||[]).map(g=>`<div class="grade"><span>${g.label}</span><span>Rang ${g.grade}</span></div>`).join('');
 $('#apply').disabled=false;$('#apply').textContent='Solliciteren →';$('#detail').classList.remove('hidden');
}
window.addEventListener('message',e=>{let m=e.data;if(m.action==='show')$('#app').classList.remove('hidden');if(m.action==='hide')$('#app').classList.add('hidden');if(m.action==='data'){jobs=m.payload.jobs||[];current=m.payload.current;renderCurrent();renderJobs();$('#app').classList.remove('hidden')}if(m.action==='myjob'){current=m.job;renderCurrent()}if(m.action==='toast')toast(m.message,m.kind)});
$$('.side').forEach(b=>b.onclick=()=>{$$('.side').forEach(x=>x.classList.remove('active'));b.classList.add('active');filter=b.dataset.filter;renderJobs()});
$('#search').oninput=renderJobs;$('#close').onclick=close;$('#detailClose').onclick=()=>$('#detail').classList.add('hidden');
$('#apply').onclick=()=>{if(!selected)return;post('apply',{job:selected.name});$('#detail').classList.add('hidden')};
$('#duty').onclick=()=>post('duty');
document.addEventListener('keydown',e=>{if(e.key==='Escape')close()});
