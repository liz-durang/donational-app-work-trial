class UkDonor < Donor
  validates :title, presence: true, length: { maximum: 4 }
  validates :first_name, presence: true, length: { maximum: 35 }
  validates :last_name, presence: true, length: { maximum: 35 }
  validates :house_name_or_number, presence: true
  validates :postcode, presence: true, format: {
    with: /\A([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? [0-9][A-Za-z]{2}|[Gg][Ii][Rr] 0[Aa]{2})\z/,
    message: 'is not a valid postcode' }
end
