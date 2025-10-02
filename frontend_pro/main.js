(function(){
  const stateTxt = document.getElementById('stateTxt');
  const dot = document.getElementById('dot');
  const clock = document.getElementById('clock');

  const steps = [
    'Inicializando interfaz',
    'Cargando estilos',
    'Montando componentes',
    'Listo para Fase 1'
  ];
  let i=0;
  function cycle(){
    stateTxt.textContent = steps[i % steps.length];
    i++;
  }
  cycle();
  setInterval(cycle, 1600);

  function tickClock(){
    const now = new Date();
    const pad = n => String(n).padStart(2,'0');
    clock.textContent = 'Hora local: ' + pad(now.getHours()) + ':' + pad(now.getMinutes()) + ':' + pad(now.getSeconds());
  }
  tickClock();
  setInterval(tickClock, 1000);
})();
