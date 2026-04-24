from datetime import datetime

def timestamp_to_datetime(value):
    """Convert a Unix timestamp to a UTC datetime string."""
    try:
        if value is None:
            return 'N/A'
        return datetime.utcfromtimestamp(int(value)).strftime('%Y-%m-%d %H:%M:%S UTC')
    except (ValueError, TypeError):
        return 'N/A'

class FilterModule(object):
    def filters(self):
        return {
            'timestamp_to_datetime': timestamp_to_datetime
        }
