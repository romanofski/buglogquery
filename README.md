buglogquery
===========

Small script to help with query/comparing fixed bugs from git history


* Install python-bugzilla, e.g.:

    /usr/bin/easy_install python-bugzilla

    or

    /usr/bin/pip install python-bugzilla

(verify ``bugzilla`` in your ``$PATH``)

* Create a configuration file and add the configuration options printed
  by the script if you run it the first time:

   vim ~/.bugquery.yaml

  Example:

    ---
    bug_status: ASSIGNED
    product: GIMP-manual
    flag: gimp-2.9+
    format: %{bug_id}: %{short_desc}
