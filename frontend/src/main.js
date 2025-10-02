const API = (path) => `http://localhost:8000/api${path}`;

async function listar() {
  const q = document.getElementById('q').value.trim();
  const url = new URL(API('/clientes/'));
  if (q) url.searchParams.set('q', q);
  const res = await fetch(url);
  const data = await res.json();
  const cont = document.getElementById('tabla');
  if (!Array.isArray(data)) { cont.innerHTML = '<p>Error al consultar</p>'; return; }
  const rows = data.map(c => `<tr>
    <td>${c.cliente_id ?? ''}</td>
    <td>${c.rfc ?? ''}</td>
    <td>${c.razon_social ?? ''}</td>
    <td>${c.email ?? ''}</td>
    <td>${c.telefono ?? ''}</td>
    <td>${c.activo ?? ''}</td>
  </tr>`).join('');
  cont.innerHTML = `<table>
    <thead><tr><th>ID</th><th>RFC</th><th>Razón Social</th><th>Email</th><th>Tel</th><th>Activo</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>`;
}

async function crear() {
  const body = {
    rfc: document.getElementById('rfc').value.trim(),
    razon_social: document.getElementById('razon').value.trim(),
    email: document.getElementById('email').value.trim() || null,
    telefono: document.getElementById('tel').value.trim() || null,
    activo: true
  };
  const res = await fetch(API('/clientes/'), {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(body)
  });
  if (!res.ok) {
    const msg = await res.text();
    alert('Error: ' + msg);
    return;
  }
  await listar();
}

window.listar = listar;
window.crear = crear;

listar();
