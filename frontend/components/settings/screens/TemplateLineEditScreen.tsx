import React, { useLayoutEffect, useState } from 'react'
import { Text, View, } from 'react-native'
import { TouchableWithoutFeedback } from 'react-native-gesture-handler'
import { RouteProp, useRoute, useNavigation } from '@react-navigation/native'
import { useQuery, useMutation } from '@apollo/client'

import { RootStackParamList } from 'components/settings/Settings'
import { GET_TEMPLATE_LINE, UPDATE_TEMPLATE_LINE } from 'components/settings/queries'
import { AllocationTemplateLine } from 'components/settings/graphql/AllocationTemplateLine'
import { LIST_BUDGETS } from 'components/budgets/queries'
import { ListBudgets } from 'components/budgets/graphql/ListBudgets'
import AppStyles from 'constants/AppStyles'
import FormInput from 'components/shared/screen/form/FormInput'
import BudgetSelect from 'components/shared/screen/form/BudgetSelect'

export default function TemplateLineEditScreen() {
  const { styles } = AppStyles()

  const navigation = useNavigation()
  const route = useRoute<RouteProp<RootStackParamList, 'Edit Template Line'>>()
  const { lineId } = route.params

  const [amount, setAmount] = useState('')
  const [budgetId, setBudgetId] = useState('')

  const { data } = useQuery<AllocationTemplateLine>(GET_TEMPLATE_LINE, { 
    variables: { id: lineId },
    onCompleted: data => {
      setAmount(data.allocationTemplateLine.amount.toDecimalPlaces(2).toFixed(2))
      setBudgetId(data.allocationTemplateLine.budget.id)
    }
  })

  const budgetQuery = useQuery<ListBudgets>(LIST_BUDGETS)
  const budgetName = budgetQuery.data?.budgets.find(b => b.id === budgetId)?.name ?? ''

  const [updateTemplateLine] = useMutation(UPDATE_TEMPLATE_LINE, {
    variables: {
      id: lineId,
      amount: amount,
      budgetId: budgetId
    }
  })

  const navigateToTemplate = () => navigation.navigate('Template', { templateId: data?.allocationTemplateLine.allocationTemplate.id })
  const saveAndGoBack = () => {
    updateTemplateLine()
    navigateToTemplate()
  }

  const headerRight = () => {
    return (
      <TouchableWithoutFeedback onPress={saveAndGoBack}>
        <Text style={styles.headerButtonText}>Save</Text>
      </TouchableWithoutFeedback>
    )
  }

  useLayoutEffect(() => navigation.setOptions({ headerTitle: '', headerRight: headerRight }))

  return (
    <View>
      <FormInput title='Amount' value={amount} setValue={setAmount} keyboardType='decimal-pad' />
      <BudgetSelect title='Expense/Goal' value={budgetName} setValue={setBudgetId} />
    </View>
  )
}