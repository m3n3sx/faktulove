<<<<<<< Current (Your changes)
from __future__ import absolute_import, unicode_literals

from celery import Celery

app = Celery('faktury_projekt',
             broker='redis://localhost:6379/0',
             backend='redis://localhost:6379/0')

# Optional configuration, but highly recommended in practice:
# . enable_utc = True
# . timezone = 'Europe/Warsaw'

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()


@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))
<<<<<<< Current (Your changes)
=======
=======
# This will make sure the app is always imported when
# Django starts so that shared_task will use this app.
from .celery import app as celery_app

__all__ = ('celery_app',)
>>>>>>> Incoming (Background Agent changes)
>>>>>>> Incoming (Background Agent changes)
