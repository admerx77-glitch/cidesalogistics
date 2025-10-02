driver = None
try:
    import psycopg as pg3  # psycopg v3
    driver = 'pg3'
    import sys; print('DRIVER', driver); print('VER', pg3.__version__)
except Exception:
    try:
        import psycopg2 as pg2  # psycopg2
        driver = 'pg2'
        import sys; print('DRIVER', driver); print('VER', pg2.__version__)
    except Exception as e:
        import sys; print('DRIVER', 'none'); print('ERR', str(e)); sys.exit(1)
