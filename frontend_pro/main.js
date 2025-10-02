(async function(){
  const el = document.getElementById('app');
  try{
    const r = await fetch('http://127.0.0.1:8000/health');
    const j = await r.json();
    el.innerHTML = <pre></pre>;
  }catch(e){
    el.innerHTML = '<b>No se pudo contactar el backend</b>';
  }
})();
