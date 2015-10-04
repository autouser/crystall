DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

admin = User.create username: 'admin', password: 'test1234', admin: true
user  = User.create username: 'user', password: 'test1234'

project1 = admin.projects.create! name: 'Core 1.0', description: 'Core System', status: 'open'
project2 = admin.projects.create! name: 'Core 2.0', description: 'Core System (development)', status: 'closed'