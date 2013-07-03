$ = jQuery

$.fx.off = true

tester =
  keydown: (k, msg, $el) ->
    $el ?= @$el
    if msg then ok true, "I press #{msg}"
    $e = $.Event('keydown')
    $e.keyCode = $e.which = k
    $el.trigger($e)
  initDropdowns: (options) ->
    defaults =
      opts: {}
      month: 12
      day: 21
      year: 2012
      months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
      days: [1..31]
      years: [2000..2020].reverse()
      blank: true
    opts = $.extend(true, defaults, options)
    $div = $(".calendar")
    $div.find(":text").remove()
    $m = $("<select />", { class: "months"} ).appendTo($div)
    $d = $("<select />", { class: "days"} ).appendTo($div)
    $y = $("<select />", { class: "years"} ).appendTo($div)
    $m.append($("<option />", { text: m, value: i+1 })) for m, i in opts.months
    $d.append($("<option />", { text: d, value: d })) for d in opts.days
    $y.append($("<option />", { text: y, value: y })) for y in opts.years
    if opts.blank
      $m.prepend($("<option />", { value: "" }))
      $d.prepend($("<option />", { value: "" }))
      $y.prepend($("<option />", { value: "" }))
    $m.val(opts.month)
    $d.val(opts.day)
    $y.val(opts.year)
    dropdown_opts =
      trigger: ".trigger",
      dropdowns:
        month: ".months"
        day: ".days"
        year: ".years"
    @$el = $(".calendar").minical($.extend(opts.opts, dropdown_opts))
  cal: (selector) ->
    $cal = @$el.data("minical").$cal
    if selector then $cal.find(selector) else $cal
  init: (opts, date) ->
    $(document).off("keydown")
    date ?= "12/1/2012"
    @$el = $(".calendar :text").val(date).minical(opts)

$.fn.getTextArray = ->
  ($(@).map -> $(@).text()).get()

$.fn.shouldHaveValue = (val) ->
  equal @.val(), val, "#{@.selector} should have a value of #{val}"
  @

$.fn.shouldBe = (attr) ->
  ok @.is(attr), "#{@.selector} should be #{attr}"
  @

$.fn.shouldNotBe = (attr) ->
  ok !@.is(attr), "#{@.selector} should not be #{attr}"
  @

$.fn.shouldSay = (text) ->
  equal @.text(), text, "#{text} is displayed within #{@.selector}"
  @

test "it is chainable", ->
  ok tester.init().hide().show().is(":visible"), "minical is invoked and visibility is toggled"

test "minical triggers on focus", ->
  $input = tester.init().focus()
  tester.cal().shouldBe(":visible")

test "minical hides on blur", ->
  $input = tester.init().blur()
  tester.cal().shouldNotBe(":visible")

test "minical hides on outside click", ->
  $input = tester.init().focus()
  tester.cal("h1").click()
  tester.cal().shouldBe(":visible")
  $("#qunit").click()
  tester.cal().shouldNotBe(":visible")

module "Rendering a month"

test "minical displays the correct month heading", ->
  $input = tester.init().focus()
  tester.cal("h1").shouldSay("Dec 2012")

test "minical displays the correct day table", ->
  $input = tester.init().focus()
  deepEqual(tester.cal("th").getTextArray(), ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], "Days of week are displayed properly")
  days = ((day + "") for day in [].concat([25..30],[1..31],[1..5]))
  deepEqual(tester.cal("td").getTextArray(), days, "days of month are displayed properly")

test "clicking a day sets input to that value", ->
  $input = tester.init().focus()
  tester.cal("td.minical_day_12_21_2012 a").click()
  tester.cal().shouldNotBe(":visible")
  $input.shouldHaveValue("12/21/2012")

test "minical fades out displayed days not of current month", ->
  $input = tester.init().focus()
  tester.cal("td:lt(7)").shouldBe(".minical_past_month")
  tester.cal("td:last").shouldBe(".minical_future_month")

test "minical highlights the current day", ->
  today = new Date()
  today_array = [today.getMonth() + 1, today.getDate(), today.getFullYear()]
  $input = tester.init({}, today_array.join("/")).focus()
  tester.cal("td.minical_day_#{today_array.join('_')}").shouldBe(".minical_today")

test "minical triggers from a separate trigger element", ->
  opts =
    trigger: ".trigger"
  $el = tester.init(opts)
  $el.data("minical").$trigger.click()
  tester.cal().shouldBe(":visible")

test "minical triggers from a trigger element defined through a function", ->
  $('.calendar').after($("<a />", class: "other_trigger"))
  opts =
    trigger: ->
      $(@).closest('.calendar').siblings().filter(".other_trigger")
  $el = tester.init(opts)
  equal($el.data("minical").$trigger.length, 1, "trigger exists")
  $el.data("minical").$trigger.click()
  tester.cal().shouldBe(":visible")

test "minical does not show from trigger if input is disabled", ->
  opts =
    trigger: ".trigger"
  $el = tester.init(opts)
  $el.prop("disabled", true)
  $el.data("minical").$trigger.click()
  tester.cal().shouldNotBe(":visible")

module "Navigating between months"

test "click to view next month", ->
  tester.init().focus()
  tester.cal(".minical_next").click()
  tester.cal("h1").shouldSay("Jan 2013")
  tester.cal().shouldBe(":visible")

test "click to view previous month", ->
  tester.init().focus()
  tester.cal(".minical_prev").click()
  tester.cal("h1").shouldSay("Nov 2012")
  tester.cal().shouldBe(":visible")

test "Minimum date specified", ->
  opts =
    from: new Date("October 4, 2012")
  $input = tester.init(opts).focus()
  tester.cal(".minical_prev").click()
  tester.cal(".minical_prev").click()
  tester.cal(".minical_prev").shouldNotBe(":visible")
  tester.cal("h1").shouldSay("Oct 2012")
  tester.cal("td.minical_day_10_4_2012").shouldNotBe(".minical_disabled")
  tester.cal("td.minical_day_10_3_2012").shouldBe(".minical_disabled").find("a").click()
  tester.cal().shouldBe(":visible")
  $input.shouldHaveValue("12/1/2012")

test "Maximum date specified", ->
  opts =
    to: new Date("February 26, 2013")
  $input = tester.init(opts).focus()
  tester.cal(".minical_next").click()
  tester.cal(".minical_next").click()
  tester.cal(".minical_next").shouldNotBe(":visible")
  tester.cal("h1").shouldSay("Feb 2013")
  tester.cal("td.minical_day_2_26_2013").shouldNotBe(".minical_disabled")
  tester.cal("td.minical_day_2_27_2013").shouldBe(".minical_disabled").find("a").click()
  tester.cal().shouldBe(":visible")
  $input.shouldHaveValue("12/1/2012")

module "Firing using dropdowns"

test "displays when trigger clicked and dropdowns specified", ->
  tester.initDropdowns().find(".trigger").click()
  tester.cal("h1").shouldSay("Dec 2012")

test "defaults to today if dropdowns are blank", ->
  options =
    month: ''
    day: ''
    year: ''
    blank: true
  today = new Date()
  today_array = [today.getMonth() + 1, today.getDate(), today.getFullYear()]
  $el = tester.initDropdowns(options)
  $el.data("minical").$trigger.click()
  tester.cal("td.minical_day_#{today_array.join('_')}").shouldBe(":visible")

test "clicking a day sets dropdowns to that value", ->
  $el = tester.initDropdowns()
  $el.data("minical").$trigger.click()
  tester.cal("td.minical_12_21_2012").click()
  $el.find(".months").shouldHaveValue(12)
  $el.find(".days").shouldHaveValue(21)
  $el.find(".years").shouldHaveValue(2012)

test "changing dropdowns updates visible calendar", ->
  $el = tester.initDropdowns()
  $el.find(".trigger").click()
  $el.find(".years option:contains('2011')").prop("selected", true).parent().change()
  tester.cal("h1").shouldSay("Dec 2011")
  tester.cal("td.minical_day_12_21_2011").shouldBe(".minical_selected")

test "Minimum date is autodetected from dropdown content", ->
  opts =
    month: 1
    day: 1
    year: 2000
  $el = tester.initDropdowns(opts).data("minical").$trigger.click()
  tester.cal("td.minical_day_12_31_1999").shouldBe(".minical_disabled")
  tester.cal("td.minical_day_1_1_2000").shouldNotBe(".minical_disabled")
  tester.cal(".minical_prev").shouldNotBe(":visible")

test "Maximum date is autodetected from dropdown content", ->
  opts =
    month: 12
    day: 25
    year: 2020
  $el = tester.initDropdowns(opts).data("minical").$trigger.click()
  tester.cal(".minical_next").shouldNotBe(":visible")

test "Dropdown date detection works with ascending or descending year values", ->
  opts =
    months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    days: [1..31]
    years: [2000..2020]
    month: 12
    day: 15
    year: 2000
  $el = tester.initDropdowns(opts)
  $el.data("minical").$trigger.click()
  tester.cal(".minical_next").click()
  tester.cal("td.minical_day_1_8_2001 a").click()
  $el.find(".months").shouldHaveValue(1)
  $el.find(".days").shouldHaveValue(8)
  $el.find(".years").shouldHaveValue(2001)
  tester.cal().shouldNotBe(":visible")

module "Testing alignment"

test "Calendar aligns to trigger if one is specified", ->
  opts =
    trigger: ".trigger"
  $el = tester.init(opts)
  $trigger = $el.data("minical").$trigger.click()
  equal $trigger.offset().left, tester.cal().show().offset().left, "Calendar and trigger left offsets are identical"
  equal $trigger.offset().top + $trigger.outerHeight() + 5, tester.cal().show().offset().top, "Calendar is 5px below trigger by default"

test "Calendar offset can be specified", ->
  opts =
    trigger: ".trigger"
    offset:
      x: 20
      y: 20
  $el = tester.init(opts)
  $trigger = $el.data("minical").$trigger.click()
  equal $trigger.offset().left + 20, tester.cal().offset().left, "Calendar is 20px to the right of trigger"
  equal $trigger.offset().top + $trigger.outerHeight() + 20, tester.cal().offset().top, "Calendar is 20px below trigger"

test "Calendar aligns to trigger if dropdowns are used", ->
  $el = tester.initDropdowns()
  $trigger = $el.data("minical").$trigger.click()
  equal $trigger.offset().left, tester.cal().offset().left, "Calendar and trigger left offsets are identical"
  equal $trigger.offset().top + $trigger.outerHeight() + 5, tester.cal().offset().top, "Calendar is 5px below trigger by default"

test "Calendar aligns to text input if no trigger is specified", ->
  $el = tester.init().focus()
  equal $el.offset().left, tester.cal().offset().left, "Calendar and input left offsets are identical"
  equal $el.offset().top + $el.outerHeight() + 5, tester.cal().offset().top, "Calendar is 5px below input by default"

test "Calendar can be overridden to align to text input", ->
  opts =
    trigger: ".trigger"
    align_to_trigger: false
  $el = tester.init(opts).focus()
  equal $el.offset().left, tester.cal().offset().left, "Calendar and input left offsets are identical"
  equal $el.offset().top + $el.outerHeight() + 5, tester.cal().offset().top, "Calendar is 5px below input by default"

test "Calendar should be appended to the body by default", ->
  tester.init()
  ok tester.cal().parent().is("body"), "Calendar is appended to the body."

test "Calendar can be overridden to append to an arbitrary element", ->
  tester.init(
    appendCalendarTo: -> this.parents(".calendar")
  )
  ok tester.cal().parent().is(".calendar"), "Calendar is appended to the .calendar element"

module "Selection feedback and keyboard support"

test "Select date in calendar on draw", ->
  tester.init().focus()
  equal tester.cal("td.minical_selected").length, 1, "Only one td with 'selected' class"
  tester.cal("td.minical_day_12_1_2012").shouldBe(".minical_selected")

test "Select date in calendar on redraw", ->
  $input = tester.init().focus()
  tester.cal("td.minical_day_12_1_2012").shouldBe(".minical_selected")
  tester.cal("td.minical_day_12_7_2012 a").click()
  $input.focus()
  equal tester.cal("td.minical_selected").length, 1, "Only one td with 'selected' class"
  tester.cal("td.minical_day_12_7_2012").shouldBe(".minical_selected")
  tester.cal("a.minical_next").click()
  equal tester.cal(".minical_selected").length, 0, "selected day was for previous month"

test "Highlight existing choice if available", ->
  tester.init({}, "12/5/2012").focus()
  tester.cal("td.minical_day_12_5_2012").shouldBe(".minical_highlighted")

test "Highlight triggers on mouse hover", ->
  tester.init().focus()
  tester.cal("td:eq(3) a").trigger("mouseover").parent().shouldBe(".minical_highlighted")
  equal tester.cal("td.minical_selected").length, 1, "Only one td with 'selected' class"

test "Enter on trigger or input toggles calendar and selects highlighted day", ->
  opts =
    trigger: ".trigger"
  $input = tester.init(opts).focus()
  tester.cal("td.minical_day_11_25_2012 a").trigger("mouseover")
  tester.keydown(13, "enter")
  tester.cal().shouldNotBe(":visible")
  $input.shouldHaveValue("11/25/2012")
  $input.data('minical').$trigger.focus()
  tester.cal("td.minical_day_11_27_2012 a").trigger("mouseover")
  tester.keydown(13, "enter")
  tester.cal().shouldNotBe(":visible")
  $input.shouldHaveValue("11/27/2012")

test "Arrow keys move around current month", ->
  tester.init().focus()
  tester.keydown(37, "left arrow")
  tester.cal("td.minical_day_11_30_2012").shouldBe(".minical_highlighted")
  tester.keydown(40, "down arrow")
  tester.cal("td.minical_day_12_7_2012").shouldBe(".minical_highlighted")
  tester.keydown(39, "right arrow")
  tester.cal("td.minical_day_12_8_2012").shouldBe(".minical_highlighted")
  tester.keydown(38, "up arrow")
  tester.cal("td.minical_day_12_1_2012").shouldBe(".minical_highlighted")

test "Arrow keys move around ends of week", ->
  tester.init().focus()
  tester.keydown(39, "right arrow")
  tester.cal("td.minical_day_12_2_2012").shouldBe(".minical_highlighted")
  tester.keydown(37, "left arrow")
  tester.cal("td.minical_day_12_1_2012").shouldBe(".minical_highlighted")

test "Arrow keys move around ends of month", ->
  tester.init().focus()
  tester.cal("td.minical_day_11_25_2012 a").trigger("mouseover")
  tester.keydown(37, "left arrow")
  tester.cal("h1").shouldSay("Nov 2012")
  tester.cal("td.minical_day_11_24_2012").shouldBe(".minical_highlighted")
  tester.keydown(40, "down arrow")
  tester.keydown(40, "down arrow")
  tester.cal("h1").shouldSay("Dec 2012")
  tester.cal("td.minical_day_12_8_2012").shouldBe(".minical_highlighted")

test "Arrow keys should not go to inaccessible months", ->
  options =
    opts:
      trigger: ".trigger"
      to: new Date("December 31, 2012")
  tester.initDropdowns(options).find(".trigger").click()
  tester.cal(".minical_next").shouldNotBe(":visible")
  tester.keydown(40, "down arrow")
  tester.keydown(40, "down arrow")
  tester.cal("td.minical_day_1_4_2013").shouldBe(".minical_highlighted")
  tester.keydown(40, "down arrow")
  tester.cal("td.minical_day_1_4_2013").shouldBe(".minical_highlighted")

test "Arrow keys fire anywhere on page as long as calendar is visible", ->
  tester.initDropdowns().find(".trigger").click()
  tester.keydown(37, "left arrow", $("body"))
  tester.cal("td.minical_day_12_20_2012").shouldBe(".minical_highlighted")

module "Other options"

test "Initialize with data-minical-initial attribute if provided", ->
  $(".calendar :text")
    .attr("data-minical-initial", "Tue Aug 07 2012 00:00:00 GMT-0400 (EDT)")
    .val("August seventh two thousand and twelvey!")
  tester.init().focus()
  tester.cal("td.minical_day_8_7_2012").shouldBe(".minical_highlighted")

test "Callback when date is changed", ->
  callback = false
  opts =
    date_changed: ->
      callback = true
  tester.init(opts).focus()
  tester.cal("td.minical_day_12_21_2012 a").click()
  ok callback, "date_changed callback fires"

test "Callback when month is drawn", ->
  callback = 0
  opts =
    month_drawn: ->
      callback += 1
  tester.init(opts).focus()
  tester.cal("a.minical_next").click()
  equal callback, 2, "month_drawn callback fires on show and month switch"

test "Allow custom date format output", ->
  opts =
    date_format: (date) ->
      return [date.getDate(), date.getMonth()+1, date.getFullYear()].join("-")
  $el = tester.init(opts).focus()
  tester.cal("td.minical_day_12_21_2012 a").click()
  $el.shouldHaveValue("21-12-2012")

QUnit.done ->
  $(".minical").remove()
