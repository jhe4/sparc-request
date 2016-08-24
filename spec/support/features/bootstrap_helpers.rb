module Features

  module BootstrapHelpers

    def bootstrap_select(class_or_id, choice)
      bootstrap_select = page.find("select#{class_or_id} + .bootstrap-select")

      bootstrap_select.click
      first('.dropdown-menu.open span.text', text: choice).click
      wait_for_javascript_to_finish
    end
  end
end