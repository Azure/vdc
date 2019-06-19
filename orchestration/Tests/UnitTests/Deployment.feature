Feature: Save data to storage account

Scenario: simple data to save

Given the data to save
Then persist data to the repository

Scenario: complex data to save

Given the complex data to save
When data is not null
But data is not simple
Then persist data to the repository
And read the 16MB data size

Scenario: complex data to save

Given the complex data to save
When data is not null
But data is not simple
Then persist data to the repository
And read the 64MB data size