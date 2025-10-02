from fastapi import APIRouter, UploadFile, File, HTTPException
from sqlalchemy import text
from pathlib import Path
from typing import List
from pydantic import BaseModel
from ..deps import get_session

router = APIRouter()
UPLOAD_ROOT = Path(__file__).resolve().parents[2] / "uploads"

class DocOut(BaseModel):
    doc_id: int
    cliente_id: int
    filename: str
    content_type: str | None = None
    file_url: str

@router.post("/{cliente_id}/upload", response_model=DocOut)
async def upload_doc(cliente_id: int, archivo: UploadFile = File(...)):
    UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
    target_dir = UPLOAD_ROOT / f"clientes/{cliente_id}"
    target_dir.mkdir(parents=True, exist_ok=True)
    dest = target_dir / archivo.filename
    data = await archivo.read()
    dest.write_bytes(data)
    file_url = f"/uploads/clientes/{cliente_id}/{archivo.filename}"

    with get_session() as session:
        row = session.execute(text("""
            INSERT INTO ciad99_clientes_docs (cliente_id, filename, content_type, file_path)
            VALUES (:cliente_id, :filename, :content_type, :file_path)
            RETURNING doc_id, cliente_id, filename, content_type, file_path;
        """), {"cliente_id": cliente_id, "filename": archivo.filename, "content_type": archivo.content_type, "file_path": str(dest)}).mappings().first()
        session.commit()

    return DocOut(doc_id=row["doc_id"], cliente_id=row["cliente_id"], filename=row["filename"], content_type=row["content_type"], file_url=file_url)

@router.get("/{cliente_id}/docs", response_model=List[DocOut])
def listar_docs(cliente_id: int):
    with get_session() as session:
        rows = session.execute(text("""
            SELECT doc_id, cliente_id, filename, content_type, file_path
            FROM ciad99_clientes_docs
            WHERE cliente_id=:cid
            ORDER BY doc_id DESC
        """), {"cid": cliente_id}).mappings().all()
    out = []
    for r in rows:
        path = Path(r["file_path"])
        try:
            rel = path.relative_to(UPLOAD_ROOT)
            url = f"/uploads/{rel.as_posix()}"
        except Exception:
            url = ""
        out.append(DocOut(doc_id=r["doc_id"], cliente_id=r["cliente_id"], filename=r["filename"], content_type=r["content_type"], file_url=url))
    return out

@router.delete("/{cliente_id}/docs/{doc_id}")
def borrar_doc(cliente_id: int, doc_id: int):
    with get_session() as session:
        row = session.execute(text("SELECT file_path FROM ciad99_clientes_docs WHERE doc_id=:d AND cliente_id=:c"), {"d": doc_id, "c": cliente_id}).mappings().first()
        if not row:
            raise HTTPException(status_code=404, detail="Documento no encontrado")
        session.execute(text("DELETE FROM ciad99_clientes_docs WHERE doc_id=:d AND cliente_id=:c"), {"d": doc_id, "c": cliente_id})
        session.commit()
    try:
        Path(row["file_path"]).unlink(missing_ok=True)
    except Exception:
        pass
    return {"status": "ok", "deleted": True, "doc_id": doc_id}
