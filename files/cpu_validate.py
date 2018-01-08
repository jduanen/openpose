#!/usr/bin/env python
#

import tensorflow as tf

# Validate basic TF install
hello = tf.constant('Hello, TensorFlow!')
sess = tf.Session()
print(sess.run(hello))
