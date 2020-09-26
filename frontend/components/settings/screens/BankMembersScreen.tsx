import React from 'react'
import {
  StyleSheet,
  ActivityIndicator,
  RefreshControl,
  Text
} from 'react-native'
import Constants from 'expo-constants'
import { useTheme, useNavigation } from '@react-navigation/native'
import { FlatList, TouchableWithoutFeedback } from 'react-native-gesture-handler'
import { LIST_BANK_MEMBERS, CREATE_BANK_MEMBER } from '../queries'
import { ListBankMembers } from '../graphql/ListBankMembers'
import { useQuery, useMutation } from '@apollo/client'
import BankMemberRow from './BankMemberRow'
import PlaidLink from 'react-native-plaid-link-sdk'

export default function BanksScreen() {
  const navigation = useNavigation()
  const { colors }: any = useTheme()

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      marginTop: Constants.statusBarHeight,
    },
    activityIndicator: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
    }
  })


  const { data, loading, refetch } = useQuery<ListBankMembers>(LIST_BANK_MEMBERS)

  const [createBankMember] = useMutation(CREATE_BANK_MEMBER, {
    update(cache, { data: { createBankMember } }) {
      const data = cache.readQuery<ListBankMembers | null>({ query: LIST_BANK_MEMBERS })

      cache.writeQuery({
        query: LIST_BANK_MEMBERS,
        data: { bankMembers: data?.bankMembers.concat([createBankMember]) }
      })
    }
  })

  if (loading && !data) return <ActivityIndicator color={colors.text} style={styles.activityIndicator} />

  const headerRight = () => {
    return (
      <PlaidLink
        clientName="Spendable"
        publicKey="37cc44ed343b19bae3920edf047df1"
        env="sandbox"
        component={(plaid: any) => {
          return (
            <TouchableWithoutFeedback onPress={plaid.onPress}>
              <Text style={{ color: colors.primary, fontSize: 20, paddingRight: 20 }}>Add</Text>
            </TouchableWithoutFeedback>
          )
        }}
        onSuccess={({ public_token: publicToken }: { public_token: String }) => createBankMember({ variables: { publicToken: publicToken } })}
        product={["transactions"]}
        language="en"
        countryCodes={["US"]}
      />
    )
  }

  navigation.setOptions({ headerRight: headerRight })

  return (
    <FlatList
      contentContainerStyle={{ paddingTop: 36, paddingBottom: 36 }}
      data={data?.bankMembers ?? []}
      renderItem={({ item }) => <BankMemberRow bankMember={item} />}
      refreshControl={<RefreshControl refreshing={loading} onRefresh={refetch} />}
    />
  )
}