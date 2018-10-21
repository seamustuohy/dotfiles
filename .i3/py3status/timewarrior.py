# -*- coding: utf-8 -*-
"""
Display tasks currently running in taskwarrior.

Configuration parameters:
    cache_timeout: refresh interval for this module (default 5)
    format: display format for this module (default '{task}')

Format placeholders:
    {task} active tasks

Requires
    task: https://taskwarrior.org/download/

Display time spent and calculate the price of your service.

Configuration parameters:
    cache_timeout: how often to update in seconds (default 5)
    config_file: file path to store the time already spent
        and restore it the next session
        (default '~/.i3/py3status/counter-config.save')
    format: output format string
        (default 'Time: {days} day {hours}:{mins:02d} Cost: {total}')
    format_money: output format string
        (default '{price}$')
    hour_price: your price per hour (default 30)
    tax: tax value (1.02 = 2%) (default 1.02)

Format placeholders:
    {days} The number of whole days in running timer
    {hours} The remaining number of whole hours in running timer
    {mins} The remaining number of whole minutes in running timer
    {secs} The remaining number of seconds in running timer
    {subtotal} The subtotal cost (time * rate)
    {tax} The tax cost, based on the subtotal cost
    {total} The total cost (subtotal + tax)
    {total_hours} The total number of whole hours in running timer
    {total_mins} The total number of whole minutes in running timer

Money placeholders:
    {price} numeric value of money

Color options:
    color_running: Running, default color_good
    color_stopped: Stopped, default color_bad

@author Seamus Tuohy <code AT seamustuohy.com>

SAMPLE OUTPUT
{'color': '#FF0000', 'full_text': u'Time: 0 day 0:00 Cost: 0.13$'}
"""

import json
import datetime
import re
STRING_NOT_INSTALLED = "isn't installed"


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
    format = '{hours} Hours Cost: {total}'

    def post_config_hook(self):
        if not self.py3.check_commands('task'):
            raise Exception(STRING_NOT_INSTALLED)

    def timeWarrior(self):
        def get_project_info(name=True, tags=False, project=False):
            task_command = 'task start.before:tomorrow status:pending export'
            task_json = json.loads(self.py3.command_output(task_command))
            info = []
            for key in ["description", "tags", "project"]:
                try:
                    info.append(task_json[0].get(key, None))
                except IndexError: # Catch if no results
                    info.append("")
            print(info)
            return info

        def describeTask(taskObj):
            return str(taskObj['id']) + ' ' + taskObj['description']
        color = self.py3.COLOR_RUNNING or self.py3.COLOR_GOOD
        task_info = get_project_info()
        name = task_info[0]
        tags = task_info[1]
        tag_string = " "
        if type(tags) == list:
            for i in tags:
                tag_string = tag_string + '"{0}" '.format(i)
        projects = task_info[2]
        project_string = " "
        if type(projects) == list:
            for i in projects:
                tag_string = project_string + '"{0}" '.format(i)
        else:
            project_string = projects
        print(project_string)
        # If both tag and project required
        if (self.parse_by_tag is True) and (self.parse_by_project is True):
            print("both")
            time_command = "something"
            time_command = 'timew summary "{0}" {1} {2}'.format(name,
                                                                 tag_string,
                                                                 self.rate_range)
        # If we only want project parsing
        elif (self.parse_by_project is True) and (project_string != " "):
            print("project")
            time_command = 'timew summary "{0}" {1}'.format(project_string, self.rate_range)
            print(time_command)
        # We only want tag parsing
        elif self.parse_by_tag is True and (tag_string != " "):
            print("tag")
            # Return empty if no time passed
            if tag_string == " ":
                return {
                    'cached_until': self.py3.time_in(self.cache_timeout),
                    'full_text': self.py3.safe_format('')
                }
            time_command = 'timew summary "{0}" {1}'.format(tag_string, self.rate_range)
        else:
            print("none")
            # Return empty if no time passed
            if name is None:
                return {
                    'cached_until': self.py3.time_in(self.cache_timeout),
                    'full_text': self.py3.safe_format('')
                }
            time_command = 'timew summary "{0}" {1}'.format(name, self.rate_range)

        # Get amount of time

        raw_output = self.py3.command_output(time_command)
        cleaned_output = [i for i in raw_output.split('\n') if i != '']
        # convert the total time into hours
        raw_total = cleaned_output[-1].strip().split(":")
        if re.match("^No filtered data found in the range.*", raw_total[0]):
            return {
                'cached_until': self.py3.time_in(self.cache_timeout),
                'full_text': self.py3.safe_format('')
            }
        parsed_time = datetime.timedelta(hours=int(raw_total[0]),
                                         minutes=int(raw_total[1]),
                                         seconds=int(raw_total[2]))
        seconds_per_min = 60
        min_per_hour = 60
        hours_per_day = 24.0 #Float to get fractions
        seconds_per_hour = seconds_per_min * min_per_hour
        # Calculate Raw Rate
        total_hours = parsed_time.total_seconds() / seconds_per_hour
        total_days = total_hours / hours_per_day
        raw_subtotal = float(self.hour_price) * total_hours

        raw_total = raw_subtotal + (raw_subtotal * float(self.tax))
        raw_subtotal_cost = self.py3.safe_format(self.format_money,
                                           {'price': '%.2f' % raw_subtotal})
        raw_total_cost = self.py3.safe_format(self.format_money,
                                              {'price': '%.2f' % raw_total})
        raw_tax_cost = self.py3.safe_format(self.format_money,
                                        {'price': '%.2f' % (raw_total - raw_subtotal)})

        # Calculate Modified Total
        modified_hours = (self.time_modifyer * total_hours) + total_hours
        modified_days = modified_hours / hours_per_day
        subtotal = float(self.hour_price) * modified_hours
        total = subtotal + (subtotal * float(self.tax))
        subtotal_cost = self.py3.safe_format(self.format_money,
                                             {'price': '%.2f' % subtotal})
        total_cost = self.py3.safe_format(self.format_money,
                                          {'price': '%.2f' % total})
        tax_cost = self.py3.safe_format(self.format_money,
                                        {'price': '%.2f' % (total - subtotal)})
        response = {
            'cached_until': self.py3.time_in(self.cache_timeout),
            'color': color,
            'full_text': self.py3.safe_format(
                self.format,
                dict(days='{0:.2f}'.format(total_days),
                     hours='{0:.2f}'.format(total_hours),
                     modified_hours='{0:.2f}'.format(modified_hours),
                     modified_days='{0:.2f}'.format(modified_days),
                     raw_subtotal=raw_subtotal_cost,
                     raw_total=raw_total_cost,
                     raw_tax=raw_tax_cost,
                     subtotal=subtotal_cost,
                     total=total_cost,
                     tax=tax_cost,
                     projects=project_string,
                     tags=tag_string)
            )
        }
        return response

if __name__ == "__main__":
    """
    Run module in test mode.
    """
    from py3status.module_test import module_test
    module_test(Py3status)
