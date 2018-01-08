#!/usr/bin/env python
#

import tensorflow as tf

# Validate basic TF install and execution on GPU
with tf.device('/gpu:0'):
    a = tf.constant([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], shape=[2, 3], name='a')
    b = tf.constant([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], shape=[3, 2], name='b')
c = tf.matmul(a, b)
sess = tf.Session(config=tf.ConfigProto(log_device_placement=True))
s = sess.run(c)
#### TODO put in test to make sure that the graph was run on gpu:0
print(s)    #### FIXME remove this when after adding test
