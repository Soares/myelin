class MyView extends Myelin.View
    sync: 'username'

class MyView extends Myelin.View
    sync: '[name=username]': 'username'

class MyView extends Myelin.View
    el: '#navbar'
    sync: '.username': 'username'

class MyView extends Myelin.View
    syncToModel:
        'username': 'input[name=username]'

class MyView extends Myelin.View
    syncToModel:
        '@username'

class MyView extends Myelin.View
    sync:
        '@username'
        test: 2
        'seventeen'
