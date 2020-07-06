import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme.dart';
import '../../model/server.dart' hide Member;
import 'right_drawer_subject.dart';

class RightDrawer extends StatelessWidget {
  static Widget inSubject({Key key}) {
    return Provider<RightDrawerSubject>(
      create: (context) => RightDrawerSubject(
        Provider.of<Server>(context, listen: false),
      ),
      child: const RightDrawer._(),
    );
  }

  const RightDrawer._();

  @override
  Widget build(BuildContext context) {
    final subject = Provider.of<RightDrawerSubject>(context);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<int>(
              stream: subject.numberOfTeamMembers,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                } else {
                  return Text(
                    'Team Members: ${snapshot.data}',
                    style: TextStyle(color: greyTextColor),
                  );
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<UnmodifiableListView<Member>>(
              stream: subject.members,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final members = snapshot.data;
                return ListView(
                  children: members.map(
                    (member) {
                      return ListTile(
                        leading: SizedBox(
                          height: 48,
                          width: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(48),
                              color: Theme.of(context).accentColor,
                            ),
                            child: Center(
                              child: Text(
                                member.iconCharacter,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    .copyWith(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: TextStyle(
                            fontWeight: member.isYou
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
