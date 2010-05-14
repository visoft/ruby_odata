Sham.define do
  first_name  { Faker::Name.first_name }
  last_name   { Faker::Name.last_name }
	email 			{ Faker::Internet.email}
end


TempAccount.blueprint do
	FirstName 		{ Sham.first_name }
	LastName      { Sham.last_name }
	Email         { Sham.email }
	Phone          '8605820000'
	CompanyName   'Acme, Inc.'
	Address        '1 Main St.'
	City           'Bristol'
	State          'CT'
	ZipCode       '06010'
	CompanyPhone  '8605820000'
	CompanyFax    '8605820001'
	DateCreated   Date.new(2010, 5, 7)
	DateEmailed   Date.new(2010, 5, 7)
	Plan 					{ Plan.make }
end

Plan.blueprint do
	Code 								'TEST'
	Name 								'Test Plan'
	Description					'Billed Monthly'
	Price  							'9.99'
	PromoDays						0
	ExpirationDate   		Date.new(2100, 12, 31)
	IsTrial							false
	FrequencyDays				30
	PayPalButtonId 			'0'
	PlanType						'Consumer'
end
