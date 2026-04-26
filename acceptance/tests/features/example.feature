Feature: Example test

    Scenario: Example with google
        When I open "https://www.google.com/?hl=en-GB" page
        Then If its visible, I "click" the "2" element with "Reject all" "text"
        And I "type" "playwright" in the "1" element with "Search" "title"
        And I "press" "Enter"
        Then I verify that "1" element with "playwright.dev" "text" is "visible"
        And I wait "1" seconds
        When I go back in the browser
        Then I verify if the URL "contains" "https://www.google.com"
        When I get a part of the URL based on "www.(.*?).com" regular expression and save it as "websiteNameVariable"
        When I "type" "websiteNameVariable"
        Then I verify that "1" element with "websiteNameVariable" "text" is "visible"
        When I "type" " test with playwright-bdd-wizard finished!"
        Then I wait "1.5" seconds
  