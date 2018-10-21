# -*- coding: utf-8 -*-
"""
"""

STRING_NOT_INSTALLED = "Notmuch isn't installed"

class Py3status:
    """
    """
    # available configuration parameters
    cache_timeout = 5
    parse_by_project = True
    parse_by_tag = False
    hour_price = 30
    tax = 0.0
    format_money = '${price}'
    time_modifyer = 0 # add [time_modifyer]*[total_time] to the total time worked
    rate_range = "som" # sod: day sow: week  som: month soy: year
    #rate_range = "year" # day month year
    format = '{new_emails}'

    def post_config_hook(self):
        if not self.py3.check_commands('notmuch'):
            raise Exception(STRING_NOT_INSTALLED)

    def notmuch(self):
        new_list = self.py3.command_output('notmuch search tag:inbox AND tag:unread')
        FINAL_NEWLINE = 1
        msg_number = len(new_list.split('\n')) - FINAL_NEWLINE
        if msg_number == 0:
            color = self.py3.COLOR_EMPTY or self.py3.COLOR_GOOD
        else:
            color = self.py3.COLOR_NOT_EMPTY or self.py3.COLOR_BAD
        response = {
            'cached_until': self.py3.time_in(self.cache_timeout),
            'color': color,
            'full_text': self.py3.safe_format(
                self.format,
                dict(new_emails='{0}'.format(msg_number))
                )
            }
        return response

if __name__ == "__main__":
    """
    Run module in test mode.
    """
    from py3status.module_test import module_test
    module_test(Py3status)
