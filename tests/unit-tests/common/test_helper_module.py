import unittest
import json
from orchestration.common import helper

class HelperTests(unittest.TestCase):

    def test_replace_properties_from_child_object_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': '${shared-services.par442_intValue' + '}',
                    }
                }
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(replaced_tokens['par4']['par44']['par441'], True)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(replaced_tokens['par4']['par44']['par442'], 1)

    def test_replace_properties_from_child_object_evaluate_next_ip_function_operands_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': 'next-ip(${shared-services.par442_strValue' + '}, 1)',
                    }
                }
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_strValue': '192.168.0.0'
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(replaced_tokens['par4']['par44']['par441'], True)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(replaced_tokens['par4']['par44']['par442'], 'next-ip(192.168.0.0, 1)')

    def test_replace_properties_from_child_object_evaluate_next_ip_function_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': 'next-ip(${shared-services.par442_strValue' + '}, 1)',
                    }
                }
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_strValue': '192.168.0.0'
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        # Let's execute operations, if any
        replaced_string = helper.operations(
            json.dumps(replaced_tokens), 
            replaced_tokens)

        replaced_tokens = \
            json.loads(replaced_string)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(replaced_tokens['par4']['par44']['par441'], True)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(replaced_tokens['par4']['par44']['par442'], '192.168.0.1')


    def test_replace_property_from_parent_object_with_string_value_from_array_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par45': '${shared-services.par45_strFromArrayValue[0]' + '}'
                },
                'par5': 'some value'
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1,
                    'par45_strFromArrayValue': [
                        'a',
                        'b'
                    ]
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par45'])
        self.assertEqual(replaced_tokens['par4']['par45'], 'a')

    def test_replace_array_index_with_dictionary_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par46': [
                        '${shared-services.par46[0].dictValue' + '}',
                        {
                            'a': 1,
                            'b': 2
                        }
                    ]
                }
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par46': [
                        {
                            'dictValue': {
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }
                        },
                        {
                            'newDictValue': {
                                'd': 2,
                                'e': False,
                                'f': 'new text'
                            }
                        }
                    ]
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par46'])
        self.assertEqual(replaced_tokens['par4']['par46'][0], dict({
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }))
    
    def test_replace_property_with_array_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par48': '${shared-services.par48_arrayValue' + '}'
                },
                'par5': 'some value'
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par48_arrayValue': [
                        'a',
                        'b',
                        'c'
                    ],
                    'par491_intValue': 10,
                    'par6_strValue': 'value'
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par48'])
        self.assertEqual(replaced_tokens['par4']['par48'], ['a','b','c'])

    def test_replace_all_tokens_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': '${shared-services.par442_intValue' + '}',
                    },
                    'par45': '${shared-services.par45_strFromArrayValue[0]' + '}',
                    'par46': [
                        '${shared-services.par46[0].dictValue' + '}',
                        {
                            'a': 1,
                            'b': 2
                        }
                    ],
                    'par47': '${shared-services.par47[1].arrayValue' + '}',
                    'par48': '${shared-services.par48_arrayValue' + '}',
                    'par49': {
                        'par491': '${shared-services.par491_intValue' + '}'
                    }
                },
                'par5': 'some value'
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1,
                    'par45_strFromArrayValue': [
                        'a',
                        'b'
                    ],
                    'par46': [
                        {
                            'dictValue': {
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }
                        },
                        {
                            'newDictValue': {
                                'd': 2,
                                'e': False,
                                'f': 'new text'
                            }
                        }
                    ],
                    'par47': [
                        {
                            'newarrayValue': [
                                {
                                    'a': 1,
                                    'b': True,
                                    'c': 'text'
                                }
                            ]
                        },
                        {
                            'arrayValue': [
                                {
                                    'd': 2,
                                    'e': False,
                                    'f': 'new text'
                                }
                            ]
                        }
                    ],
                    'par48_arrayValue': [
                        'a',
                        'b',
                        'c'
                    ],
                    'par491_intValue': 10,
                    'par6_strValue': 'value'
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(replaced_tokens['par4']['par44']['par441'], True)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(replaced_tokens['par4']['par44']['par442'], 1)

        self.assertIsNotNone(replaced_tokens['par4']['par45'])
        self.assertEqual(type(replaced_tokens['par4']['par45']), str)

        self.assertIsNotNone(replaced_tokens['par4']['par46'])
        self.assertEqual(type(replaced_tokens['par4']['par46'][0]), dict)

        self.assertIsNotNone(replaced_tokens['par4']['par47'])
        self.assertEqual(type(replaced_tokens['par4']['par47']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par48'])
        self.assertEqual(type(replaced_tokens['par4']['par48']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par49']['par491'])
        self.assertEqual(type(replaced_tokens['par4']['par49']['par491']), int)

    def test_replace_all_tokens_with_root_string_token_value_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': '${shared-services.par442_intValue' + '}',
                    },
                    'par45': '${shared-services.par45_strFromArrayValue[0]' + '}',
                    'par46': [
                        '${shared-services.par46[0].dictValue' + '}',
                        {
                            'a': 1,
                            'b': 2
                        }
                    ],
                    'par47': '${shared-services.par47[1].arrayValue' + '}',
                    'par48': '${shared-services.par48_arrayValue' + '}',
                    'par49': {
                        'par491': '${shared-services.par491_intValue' + '}'
                    }
                },
                'par5': 'some value',
                'par6': '${shared-services.par6_strValue' + '}'
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1,
                    'par45_strFromArrayValue': [
                        'a',
                        'b'
                    ],
                    'par46': [
                        {
                            'dictValue': {
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }
                        },
                        {
                            'newDictValue': {
                                'd': 2,
                                'e': False,
                                'f': 'new text'
                            }
                        }
                    ],
                    'par47': [
                        {
                            'newarrayValue': [
                                {
                                    'a': 1,
                                    'b': True,
                                    'c': 'text'
                                }
                            ]
                        },
                        {
                            'arrayValue': [
                                {
                                    'd': 2,
                                    'e': False,
                                    'f': 'new text'
                                }
                            ]
                        }
                    ],
                    'par48_arrayValue': [
                        'a',
                        'b',
                        'c'
                    ],
                    'par491_intValue': 10,
                    'par6_strValue': 'value'
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par441']), bool)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par442']), int)

        self.assertIsNotNone(replaced_tokens['par4']['par45'])
        self.assertEqual(type(replaced_tokens['par4']['par45']), str)

        self.assertIsNotNone(replaced_tokens['par4']['par46'])
        self.assertEqual(type(replaced_tokens['par4']['par46'][0]), dict)

        self.assertIsNotNone(replaced_tokens['par4']['par47'])
        self.assertEqual(type(replaced_tokens['par4']['par47']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par48'])
        self.assertEqual(type(replaced_tokens['par4']['par48']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par49']['par491'])
        self.assertEqual(type(replaced_tokens['par4']['par49']['par491']), int)

        self.assertIsNotNone(replaced_tokens['par6'])
        self.assertEqual(type(replaced_tokens['par6']), str)

    def test_replace_all_tokens_with_root_array_token_value_and_no_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': '${shared-services.par442_intValue' + '}',
                    },
                    'par45': '${shared-services.par45_strFromArrayValue[0]' + '}',
                    'par46': [
                        '${shared-services.par46[0].dictValue' + '}',
                        {
                            'a': 1,
                            'b': 2
                        }
                    ],
                    'par47': '${shared-services.par47[1].arrayValue' + '}',
                    'par48': '${shared-services.par48_arrayValue' + '}',
                    'par49': {
                        'par491': '${shared-services.par491_intValue' + '}'
                    }
                },
                'par5': 'some value',
                'par6': '${shared-services.par6_arrayValue' + '}'
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1,
                    'par45_strFromArrayValue': [
                        'a',
                        'b'
                    ],
                    'par46': [
                        {
                            'dictValue': {
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }
                        },
                        {
                            'newDictValue': {
                                'd': 2,
                                'e': False,
                                'f': 'new text'
                            }
                        }
                    ],
                    'par47': [
                        {
                            'newarrayValue': [
                                {
                                    'a': 1,
                                    'b': True,
                                    'c': 'text'
                                }
                            ]
                        },
                        {
                            'arrayValue': [
                                {
                                    'd': 2,
                                    'e': False,
                                    'f': 'new text'
                                }
                            ]
                        }
                    ],
                    'par48_arrayValue': [
                        'a',
                        'b',
                        'c'
                    ],
                    'par491_intValue': 10,
                    'par6_arrayValue': [
                        1,
                        2,
                        3
                    ]
                }
            })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par441']), bool)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par442']), int)

        self.assertIsNotNone(replaced_tokens['par4']['par45'])
        self.assertEqual(type(replaced_tokens['par4']['par45']), str)

        self.assertIsNotNone(replaced_tokens['par4']['par46'])
        self.assertEqual(type(replaced_tokens['par4']['par46'][0]), dict)

        self.assertIsNotNone(replaced_tokens['par4']['par47'])
        self.assertEqual(type(replaced_tokens['par4']['par47']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par48'])
        self.assertEqual(type(replaced_tokens['par4']['par48']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par49']['par491'])
        self.assertEqual(type(replaced_tokens['par4']['par49']['par491']), int)

        self.assertIsNotNone(replaced_tokens['par6'])
        self.assertEqual(type(replaced_tokens['par6']), list)

    def test_replace_all_tokens_with_an_environment_key_that_contains_multiple_properties(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': '${shared-services.par442_intValue' + '}',
                    },
                    'par45': '${shared-services.par45_strFromArrayValue[0]' + '}',
                    'par46': [
                        '${shared-services.par46[0].dictValue' + '}',
                        {
                            'a': 1,
                            'b': 2
                        }
                    ],
                    'par47': '${shared-services.par47[1].arrayValue' + '}',
                    'par48': '${shared-services.par48_arrayValue' + '}',
                    'par49': {
                        'par491': '${shared-services.par491_intValue' + '}'
                    }
                },
                'par5': 'some value',
                'par6': 'main-module/v1.0/${ENV:ENVIRONMENT-TYPE' + '.prop1.prop2}',
                'par7': '${shared-services.par7_strValue' + '}',
                'par8': [
                    1,
                    2,
                    '${shared-services.par8_intValue' + '}'
                ],
                'par9': [
                    {
                        'par91': 'value91',
                        'par92': 'value92',
                        'par93': '${shared-services.par93.arrayValue' + '}'
                    }
                ]
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'prop1': {
                        'prop2': 'hello'
                    },
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1,
                    'par45_strFromArrayValue': [
                        'a',
                        'b'
                    ],
                    'par46': [
                        {
                            'dictValue': {
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }
                        },
                        {
                            'newDictValue': {
                                'd': 2,
                                'e': False,
                                'f': 'new text'
                            }
                        }
                    ],
                    'par47': [
                        {
                            'newarrayValue': [
                                {
                                    'a': 1,
                                    'b': True,
                                    'c': 'text'
                                }
                            ]
                        },
                        {
                            'arrayValue': [
                                {
                                    'd': 2,
                                    'e': False,
                                    'f': 'new text'
                                }
                            ]
                        }
                    ],
                    'par48_arrayValue': [
                        'a',
                        'b',
                        'c'
                    ],
                    'par491_intValue': 10,
                    'par7_strValue': 'hello world',
                    'par8_intValue': 20,
                    'par93': {
                        'arrayValue': [
                            'a',
                            'b',
                            'c'
                        ]
                    }
                }
            })

        environment_keys = dict({
            'ENV:ENVIRONMENT-TYPE': 'shared-services',
            'ENV:RESOURCE-GROUP-NAME': None,
            'ENV:RESOURCE': None
        })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=environment_keys,
                storage_access=None,
                validation_mode=False)
                
        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par441']), bool)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par442']), int)

        self.assertIsNotNone(replaced_tokens['par4']['par45'])
        self.assertEqual(type(replaced_tokens['par4']['par45']), str)

        self.assertIsNotNone(replaced_tokens['par4']['par46'])
        self.assertEqual(type(replaced_tokens['par4']['par46'][0]), dict)

        self.assertIsNotNone(replaced_tokens['par4']['par47'])
        self.assertEqual(type(replaced_tokens['par4']['par47']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par48'])
        self.assertEqual(type(replaced_tokens['par4']['par48']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par49']['par491'])
        self.assertEqual(type(replaced_tokens['par4']['par49']['par491']), int)

        self.assertIsNotNone(replaced_tokens['par6'])
        self.assertEqual(type(replaced_tokens['par6']), str)
        self.assertEqual(replaced_tokens['par6'], 'main-module/v1.0/hello')

        self.assertIsNotNone(replaced_tokens['par7'])
        self.assertEqual(type(replaced_tokens['par7']), str)
        self.assertEqual(replaced_tokens['par7'], 'hello world')

        self.assertIsNotNone(replaced_tokens['par8'][2])
        self.assertEqual(type(replaced_tokens['par8'][2]), int)
        self.assertEqual(replaced_tokens['par8'][2], 20)

    def test_replace_all_tokens_with_environment_keys(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441.boolValue' + '}',
                        'par442': '${shared-services.par442_intValue' + '}',
                    },
                    'par45': '${shared-services.par45_strFromArrayValue[0]' + '}',
                    'par46': [
                        '${shared-services.par46[0].dictValue' + '}',
                        {
                            'a': 1,
                            'b': 2
                        }
                    ],
                    'par47': '${shared-services.par47[1].arrayValue' + '}',
                    'par48': '${shared-services.par48_arrayValue' + '}',
                    'par49': {
                        'par491': '${shared-services.par491_intValue' + '}'
                    }
                },
                'par5': 'some value',
                'par6': 'main-module/v1.0/${ENV:ENVIRONMENT-TYPE' + '}',
                'par61': '${shared-services.par7_strValue' + '}/v1.0/${ENV:ENVIRONMENT-TYPE' + '}',
                'par7': '${shared-services.par7_strValue' + '}',
                'par8': [
                    1,
                    2,
                    '${shared-services.par8_intValue' + '}'
                ],
                'par9': [
                    {
                        'par91': 'value91',
                        'par92': 'value92',
                        'par93': '${shared-services.par93.arrayValue' + '}'
                    }
                ]
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': {
                        'boolValue': True
                    },
                    'par442_intValue': 1,
                    'par45_strFromArrayValue': [
                        'a',
                        'b'
                    ],
                    'par46': [
                        {
                            'dictValue': {
                                'a': 1,
                                'b': True,
                                'c': 'text'
                            }
                        },
                        {
                            'newDictValue': {
                                'd': 2,
                                'e': False,
                                'f': 'new text'
                            }
                        }
                    ],
                    'par47': [
                        {
                            'newarrayValue': [
                                {
                                    'a': 1,
                                    'b': True,
                                    'c': 'text'
                                }
                            ]
                        },
                        {
                            'arrayValue': [
                                {
                                    'd': 2,
                                    'e': False,
                                    'f': 'new text'
                                }
                            ]
                        }
                    ],
                    'par48_arrayValue': [
                        'a',
                        'b',
                        'c'
                    ],
                    'par491_intValue': 10,
                    'par7_strValue': 'hello world',
                    'par8_intValue': 20,
                    'par93': {
                        'arrayValue': [
                            'a',
                            'b',
                            'c'
                        ]
                    }
                }
            })

        environment_keys = dict({
            'ENV:ENVIRONMENT-TYPE': 'shared-services',
            'ENV:RESOURCE-GROUP-NAME': None,
            'ENV:RESOURCE': None
        })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=environment_keys,
                storage_access=None,
                validation_mode=False)
                
        self.assertIsNotNone(replaced_tokens['par4']['par44']['par441'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par441']), bool)

        self.assertIsNotNone(replaced_tokens['par4']['par44']['par442'])
        self.assertEqual(type(replaced_tokens['par4']['par44']['par442']), int)

        self.assertIsNotNone(replaced_tokens['par4']['par45'])
        self.assertEqual(type(replaced_tokens['par4']['par45']), str)

        self.assertIsNotNone(replaced_tokens['par4']['par46'])
        self.assertEqual(type(replaced_tokens['par4']['par46'][0]), dict)

        self.assertIsNotNone(replaced_tokens['par4']['par47'])
        self.assertEqual(type(replaced_tokens['par4']['par47']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par48'])
        self.assertEqual(type(replaced_tokens['par4']['par48']), list)

        self.assertIsNotNone(replaced_tokens['par4']['par49']['par491'])
        self.assertEqual(type(replaced_tokens['par4']['par49']['par491']), int)

        self.assertIsNotNone(replaced_tokens['par6'])
        self.assertEqual(type(replaced_tokens['par6']), str)
        self.assertEqual(replaced_tokens['par6'], 'main-module/v1.0/shared-services')

        self.assertIsNotNone(replaced_tokens['par7'])
        self.assertEqual(type(replaced_tokens['par7']), str)
        self.assertEqual(replaced_tokens['par7'], 'hello world')

        self.assertIsNotNone(replaced_tokens['par8'][2])
        self.assertEqual(type(replaced_tokens['par8'][2]), int)
        self.assertEqual(replaced_tokens['par8'][2], 20)

    def test_token_replace_nested_parameters(self):
        parameters_with_tokens = dict({
            "general": {
                "organization-name": "org",
                "tenant-id": "00000000-0000-0000-0000-000000000000",
                "deployment-user-id": "00000000-0000-0000-0000-000000000000",
                "vdc-storage-account-name": "storage",
                "vdc-storage-account-rg": "vdc-storage-rg",
                "module-deployment-order": [
                    "la",
                    "nsg",
                    "workload-net",
                    "workload-kv",
                    "sqldb",
                    "ase"
                ],
                "validation-dependencies": [
                    "workload-kv"
                ]
            },
            "on-premises": {
                "address-range": "192.168.1.0/28",
                "primaryDC-IP": "192.168.1.4",
                "allow-rdp-address-range": "192.168.1.4"
            },
            "shared-services": {
                "subscription-id": "00000000-0000-0000-0000-000000000000",
                "vnet-rg": "org-ssvcs-net-rg",
                "vnet-name": "org-ssvcs-vnet",
                "app-gateway-subnet-name": "AppGateway",
                "app-gateway-name": "org-ssvcs-app-gw",
                "gw-udr-name": "org-ssvcs-gw-udr",
                "kv-rg": "org-ssvcs-kv-rg",
                "kv-name": "org-ssvcs-kv",
                "shared-services-subnet-address-prefix": "10.4.0.32/27",
                "azure-firewall-private-ip-address": "10.4.1.4",
                "azure-firewall-name": "org-ssvcs-az-fw",
                "ubuntu-nva-lb-ip-address": "10.4.0.20",
                "ubuntu-nva-address-start": "10.4.0.5",
                "squid-nva-address-start": "10.4.0.5",
                "deployment-name": "ssvcs",
                "adds-address-start": "10.4.0.46",
                "domain-name": "contoso.com",
                "domain-admin-user": "contoso",
                "network": {
                    "address-prefix": "10.4.4.0/23",
                    "application-security-groups": [],
                    "virtual-appliance": {
                        "egress-ip": "${shared-services.network.virtual-appliance.azure-firewall.egress.ip}",
                        "azure-firewall": {
                            "ingress": {
                                "vm-ip-address-start": ""
                            },
                            "egress": {
                                "ip": "10.4.1.4",
                                "vm-ip-address-start": ""
                            }
                        },
                        "palo-alto": {
                            "ingress": {
                                "vm-ip-address-start": "10.4.0.43"
                            },
                            "egress": {
                                "ip": "10.4.0.50",
                                "vm-ip-address-start": "10.4.0.40"
                            },
                            "image": {
                                "offer": "vmseries1",
                                "publisher": "paloaltonetworks",
                                "sku": "bundle2",
                                "version": "latest"
                            },
                            "enable-bootstrap": True
                        },
                        "custom-ubuntu": {
                            "ingress": {
                                "vm-ip-address-start": ""
                            },
                            "egress": {
                                "ip": "10.4.0.20",
                                "vm-ip-address-start": "10.4.0.5"
                            }
                        },
                        "squid": {
                            "ingress": {
                                "vm-ip-address-start": ""
                            },
                            "egress": {
                                "ip": "",
                                "vm-ip-address-start": "10.4.0.5"
                            }
                        }
                    }
                }
            },
            "workload": {
                "subscription-id": "00000000-0000-0000-0000-000000000000",
                "deployment-name": "paas",
                "region": "Central US",
                "ancillary-region": "East US",
                "log-analytics-region": "West US 2",
                "local-admin-user": "admin-user",
                "encryption-keys-for": [],
                "enable-encryption": False,
                "enable-ddos-protection": False,
                "enable-vnet-peering": True
            }
        })

        parameter_token_values = dict({
            "general": {
                "organization-name": "org",
                "tenant-id": "00000000-0000-0000-0000-000000000000",
                "deployment-user-id": "00000000-0000-0000-0000-000000000000",
                "vdc-storage-account-name": "storage",
                "vdc-storage-account-rg": "vdc-storage-rg",
                "module-deployment-order": [
                    "la",
                    "nsg",
                    "workload-net",
                    "workload-kv",
                    "sqldb",
                    "ase"
                ],
                "validation-dependencies": [
                    "workload-kv"
                ]
            },
            "on-premises": {
                "address-range": "192.168.1.0/28",
                "primaryDC-IP": "192.168.1.4",
                "allow-rdp-address-range": "192.168.1.4"
            },
            "shared-services": {
                "subscription-id": "00000000-0000-0000-0000-000000000000",
                "vnet-rg": "org-ssvcs-net-rg",
                "vnet-name": "org-ssvcs-vnet",
                "app-gateway-subnet-name": "AppGateway",
                "app-gateway-name": "org-ssvcs-app-gw",
                "gw-udr-name": "org-ssvcs-gw-udr",
                "kv-rg": "org-ssvcs-kv-rg",
                "kv-name": "org-ssvcs-kv",
                "shared-services-subnet-address-prefix": "10.4.0.32/27",
                "azure-firewall-private-ip-address": "10.4.1.4",
                "azure-firewall-name": "org-ssvcs-az-fw",
                "ubuntu-nva-lb-ip-address": "10.4.0.20",
                "ubuntu-nva-address-start": "10.4.0.5",
                "squid-nva-address-start": "10.4.0.5",
                "deployment-name": "ssvcs",
                "adds-address-start": "10.4.0.46",
                "domain-name": "contoso.com",
                "domain-admin-user": "contoso",
                "network": {
                    "address-prefix": "10.4.4.0/23",
                    "application-security-groups": [],
                    "virtual-appliance": {
                        "egress-ip": "${shared-services.network.virtual-appliance.azure-firewall.egress.ip}",
                        "azure-firewall": {
                            "ingress": {
                                "vm-ip-address-start": ""
                            },
                            "egress": {
                                "ip": "10.4.1.4",
                                "vm-ip-address-start": ""
                            }
                        },
                        "palo-alto": {
                            "ingress": {
                                "vm-ip-address-start": "10.4.0.43"
                            },
                            "egress": {
                                "ip": "10.4.0.50",
                                "vm-ip-address-start": "10.4.0.40"
                            },
                            "image": {
                                "offer": "vmseries1",
                                "publisher": "paloaltonetworks",
                                "sku": "bundle2",
                                "version": "latest"
                            },
                            "enable-bootstrap": True
                        },
                        "custom-ubuntu": {
                            "ingress": {
                                "vm-ip-address-start": ""
                            },
                            "egress": {
                                "ip": "10.4.0.20",
                                "vm-ip-address-start": "10.4.0.5"
                            }
                        },
                        "squid": {
                            "ingress": {
                                "vm-ip-address-start": ""
                            },
                            "egress": {
                                "ip": "",
                                "vm-ip-address-start": "10.4.0.5"
                            }
                        }
                    }
                }
            },
            "workload": {
                "subscription-id": "00000000-0000-0000-0000-000000000000",
                "deployment-name": "paas",
                "region": "Central US",
                "ancillary-region": "East US",
                "log-analytics-region": "West US 2",
                "local-admin-user": "admin-user",
                "encryption-keys-for": [],
                "enable-encryption": False,
                "enable-ddos-protection": False,
                "enable-vnet-peering": True
            }
        })

        replaced_tokens = \
            helper.replace_all_tokens(
                dict_with_tokens=parameters_with_tokens, 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                environment_keys=None,
                storage_access=None,
                validation_mode=False)

        self.assertEqual(replaced_tokens['shared-services']['network']['virtual-appliance']['egress-ip'], '10.4.1.4')

    def test_get_current_milliseconds(self):
        self.assertEqual(type(helper.get_current_time_milli()), int)

    def test_cleanse_output_parameters(self):
        output_parameters = dict({
            'type': 'String',
            'par': 'Value'
        })

        cleansed_output_parameters = \
            helper.cleanse_output_parameters(json.dumps(output_parameters))

        self.assertEqual(json.loads(cleansed_output_parameters), dict({
            'par': 'Value'
        }))

    def test_sort_module_deployment(self):
        unsorted_list = ['a', 'b', '1', '3', 'c']
        source_order_list = ['a', '1', 'b', 'c', '3']

        sorted_list = helper.sort_module_deployment(
            unsorted_list,
            source_order_list)
        
        self.assertEqual(sorted_list, source_order_list)

    def test_has_token(self):
        token = '${this.is.a.token' + '}'

        self.assertEqual(helper.has_token(token), True)

    def test_replace_string_tokens(self):
        parameters_with_tokens = \
            dict({
                'par1': 'value',
                'par2': True,
                'par3': 1,
                'par4': {
                    'par41': 'value41',
                    'par42': False,
                    'par43': 2,
                    'par44': {
                        'par441': '${shared-services.par441' + '}',
                        'par442': '${shared-services.par442' + '}',
                    }
                }
            })

        parameter_token_values = \
            dict({
                'shared-services': {
                    'par441': 'True',
                    'par442': '1'
                }
            })

        replaced_tokens = \
            helper.replace_string_tokens(
                full_text_with_tokens=json.dumps(parameters_with_tokens), 
                parameters=parameter_token_values, 
                organization_name='contoso',
                shared_services_deployment_name='shared-services',
                workload_deployment_name='workload',
                storage_container_name='storage',
                storage_access=None,
                validation_mode=False)

        self.assertEqual(helper.has_token(replaced_tokens), False)

    def test_next_ip_operation(self):
        token_with_operation = 'next-ip(10.0.0.0, 1)'
        token_replaced = helper.operations(token_with_operation, dict())

        self.assertEqual(token_replaced, '10.0.0.1')

    def test_truncate_string_arguments(self):
        text = '0123456789'

        self.assertEqual(helper.truncate_string_arguments(2, text), '01')

    def test_create_unique_string(self):
        text = 'storage'
        current_milliseconds = helper.get_current_time_milli()
        unique_value = '{}{}'.format(
            text,
            current_milliseconds)

        self.assertEqual(unique_value, helper.create_unique_string(text, 24))

if __name__ == '__main__':
    unittest.main()