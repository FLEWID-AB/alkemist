# The query dialect

Index pages are driven by query parameters that filter forms, sortable headers, scope tabs
and pagination links emit. Bookmarks and integrations can build them by hand.

| parameter | example | meaning |
|---|---|---|
| `q[<field>_<op>]` | `q[title_cont]=hello` | filter (see operators) |
| `q[<assoc>_assoc_<field>_<op>]` | `q[category_assoc_name_eq]=News` | filter on an association's column |
| `s` | `s=title+desc` (or `title desc`) | sort; `asc`, `desc`, `asc_nulls_last`, ... |
| `scope` | `scope=published` | active scope |
| `page`, `per_page` | `page=2&per_page=50` | pagination (`per_page` capped by config) |

## Operators

| suffix | meaning | notes |
|---|---|---|
| `eq`, `neq` | equal / not equal | a list with `eq` means `in` |
| `lt`, `lteq`, `gt`, `gteq` | comparisons | |
| `in`, `not_in` | membership | list params or comma-separated |
| `cont`, `ilike` / `not_cont`, `not_ilike` | contains (case-insensitive) | the default when no suffix is given |
| `start`, `not_start`, `end`, `not_end` | starts / ends with | |
| `null`, `not_null` | is null / is not null | value `true`/`false` |

Values are cast with the column's Ecto type; uncastable values and unknown fields are
ignored (logged at debug level, key names only). A date-only value on a datetime column
covers the whole day: `published_at_eq=2026-01-02` means `>= 2026-01-02 00:00` and
`< 2026-01-03 00:00`; `lteq` includes the day. LIKE metacharacters in values are escaped.

Filters on `has_many`/`many_to_many` associations use a semi-join, so rows are never
duplicated and counts stay correct; `belongs_to`/`has_one` use one left join and can also
be sorted on.

## Providers

`config :my_app, Alkemist, query: [search: Mod, paginate: Mod]` swaps the implementation.
Search providers implement `Alkemist.Query.SearchProvider` (`filter/3`, `sort/3`, `run/3`),
pagination providers `Alkemist.Query.PaginationProvider` (`run/3` returning
`{query, %Alkemist.Query.Page{}}`). `opts` carries `:schema`, `:repo`, `:otp_app` and
`:timezone`.
