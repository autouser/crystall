DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

admin = User.create username: 'admin', password: 'test1234', admin: true
user  = User.create username: 'user', password: 'test1234'
