import disnake
from disnake.ext import commands
import os
from disnake.ext.commands import bot_base
from disnake.utils import get
import asyncio
import datetime
import time
import socket
import random
import logging
import re
from disnake.ui import Button, View

LOG_CHANNEL_ID = 1286670875323797626

intents = disnake.Intents.all()
intents.voice_states = True
intents.messages = True
intents.members = True
bot = commands.Bot(command_prefix="!", help_command=None, intents=intents)
bot.remove_command("help")

banned_words = ["Ты уебан", "уебан", "Уебан", "Ты уебище", "уебище", "Уебище"]


# Filters
invitation_filter = re.compile(r'(discord\.gg|discord\.com\/invite)\/[a-zA-Z0-9]+')
link_filter = re.compile(r'https?://[^\s]+')
scam_filter = re.compile(r'(free|win|giveaway|prize|ancial|account|password|credit)[\s\S]*')
phishing_filter = re.compile(r'(login|sign|signup|download|install|update)[\s\S]*')
profanity_filter = re.compile(r'(bad|evil|swear)[\s\S]*')

@bot.event
async def on_message(message):
    if message.author.bot:
        return
    if invitation_filter.search(message.content):
        await message.delete()
        await message.channel.send(f"{message.author.mention}, приглашения в другие серверы запрещены!")
    elif link_filter.search(message.content):
        await message.delete()
        await message.channel.send(f"{message.author.mention}, ссылки не разрешены!")
    elif scam_filter.search(message.content):
        await message.delete()
        await message.channel.send(f"{message.author.mention}, мошенничество запрещено!")
    elif phishing_filter.search(message.content):
        await message.delete()
        await message.channel.send(f"{message.author.mention}, фишинг запрещен!")
    elif profanity_filter.search(message.content):
        await message.delete()
        await message.channel.send(f"{message.author.mention}, оскорбления запрещены!")
    else:
        await bot.process_commands(message)

@bot.event
async def on_message(message):
    # Check if the message contains any banned words
    for word in banned_words:
        if word in message.content.lower():
            # Delete the message
            await message.delete()
            # Warn the user
            await message.channel.send(f"{message.author.mention} Пожалуйста, воздержитесь от использования ненормативной лексики.")

    # Process other commands
    await bot.process_commands(message)

@bot.command()
async def kick(ctx, member: disnake.Member, reason: str):
    if ctx.author.guild_permissions.kick_members:
        await member.kick(reason=reason)
        await ctx.send(f"{member.mention} был кикнут с сервера!")
    else:
        await ctx.send("У вас нет разрешения кикнуть участников!")

@bot.command()
async def role(ctx):
    author = ctx.message.author
    guild = bot.get_guild(1286628395567939646)
    role = guild.get_role(1286635111453818881)
    

    await author.add_roles(role)

@bot.command()
async def тести(ctx):

    async def button_callback(interaction):
        await interaction.response.edit_message(content='Button clicked!', view=None)

    button = Button(custom_id='button1', label='WOW button!', style=disnake.ButtonStyle.green)
    button.callback = button_callback

    await ctx.send('Hello World!', view=View(button))

@bot.command()
async def add_banned_word(ctx, word: str):
    # Add the word to the banned words list
    banned_words.append(word)
    await ctx.send(f"{word} добавлен в список запрещенных слов.")

@bot.command()
async def remove_banned_word(ctx, word: str):
    # Remove the word from the banned words list
    if word in banned_words:
        banned_words.remove(word)
        await ctx.send(f"{word} было удалено из списка запрещенных слов.")
    else:
        await ctx.send(f"{word} нет в списке запрещенных слов.")

@bot.command()
async def ban(ctx, member: disnake.Member, reason: str = "Причина не указана"):
    if ctx.author.guild_permissions.ban_members:
        await member.ban(reason=reason)
        embed = disnake.Embed(title="Участник забанен", description=f"{member.mention} был забанен на сервере.", color=0xff0000)
        embed.add_field(name="Причина", value=reason, inline=False)
        await ctx.send(embed=embed)
    else:
        await ctx.send("У вас нет разрешения банить участников.")
        await ctx.message.delete()

@bot.command()
async def unban(ctx, member: disnake.Member, reason: str = "Причина  не указана"):
    if ctx.author.guild_permissions.ban_members:
        await ctx.guild.unban(member, reason=reason)
        embed = disnake.Embed(title="Участник разблокирован", description=f"{member.mention} был разбанен на сервере.", color=0x00ff00)
        embed.add_field(name="Причина", value=reason, inline=False)
        await ctx.send(embed=embed)
    else:
        await ctx.send("У вас нет разрешения на разблокировку участников.")
        await ctx.message.delete()

@bot.command()
async def mute(ctx, member: disnake.Member, duration: int, reason: str = "Причина не указана"):
    if ctx.author.guild_permissions.manage_roles:
        mute_role = disnake.utils.get(ctx.guild.roles, name="mute")
        if mute_role is None:
            await ctx.send("Роли «Приглушено» не существует. Пожалуйста, создайте его и повторите попытку.")
        else:
            await member.add_roles(mute_role)
            overwrite = disnake.PermissionOverwrite()
            overwrite.send_messages = False
            await ctx.channel.set_permissions(member, overwrite=overwrite)
            embed = disnake.Embed(title="Звук участника отключен", description=f"{member.mention} был отключен для {duration} минуты.", color=0xff9900)
            embed.add_field(name="Причина", value=reason, inline=False)
            await ctx.send(embed=embed)
            await asyncio.sleep(duration * 60)
            await member.remove_roles(mute_role)
            await ctx.channel.set_permissions(member, overwrite=None)
    else:
        await ctx.send("У вас недостаточно прав для отключения микрофонов участников.")
        await ctx.message.delete()

@bot.command()
async def unmute(ctx, member: disnake.Member, reason: str = "Причина не указана"):
    if ctx.author.guild_permissions.manage_roles:
        mute_role = disnake.utils.get(ctx.guild.roles, name="mute")
        if mute_role is None:
            await ctx.send("Роли «Приглушено» не существует. Пожалуйста, создайте его и повторите попытку.")
        else:
            await member.remove_roles(mute_role)
            await ctx.channel.set_permissions(member, overwrite=None)
            embed = disnake.Embed(title="Участник без звука", description=f"{member.mention} был включен звук.", color=0x00ff00)
            embed.add_field(name="Причина", value=reason, inline=False)
            await ctx.send(embed=embed)
    else:
        await ctx.send("У вас недостаточно прав для включения микрофонов участников.")
        await ctx.message.delete()

@bot.command(name="очистить", description="Очистить чат")
async def clear_chat(ctx, amount: int = 100):
    if ctx.author.guild_permissions.manage_messages:
        await ctx.channel.purge(limit=amount)
        embed = disnake.Embed(title="Чат очищен", description=f"Сообщений {amount} удалено.", color=0x00ff00)
        await ctx.send(embed=embed)
    else:
        await ctx.send("У вас нет разрешения на очистку чата.")
        await ctx.channel.purge(limit = amount)

@bot.command()
async def verify(ctx, username: str, discriminator: int):
    if ctx.author.guild_permissions.administrator:
        member = ctx.guild.get_member_named(f"{username}#{discriminator}")
        if member:
            role = disnake.utils.get(ctx.guild.roles, name="Участник")
            await member.add_roles(role)
            await ctx.send(f"{member.mention} has been verified!")
        else:
            await ctx.send("Member not found!")
    else:
        await ctx.send("You don't have permission to verify users!")

@bot.command()
async def unverify(ctx, username: str, discriminator: int):
    if ctx.author.guild_permissions.administrator:
        member = ctx.guild.get_member_named(f"{username}#{discriminator}")
        if member:
            role = disnake.utils.get(ctx.guild.roles, name="Участник")
            await member.remove_roles(role)
            await ctx.send(f"{member.mention} has been unverified!")
        else:
            await ctx.send("Member not found!")
    else:
        await ctx.send("You don't have permission to unverify users!")

warnings = {}

@bot.command()
async def warn(ctx, member: disnake.Member, reason: str):
    if ctx.author.guild_permissions.administrator:
        if member not in warnings:
            warnings[member.id] = 1
        else:
            warnings[member.id] += 1
            await ctx.send(f"{member.mention} был предупрежден! Причина: {reason}")
            await member.send(f"Вас предупредили в {ctx.guild.name} для {reason}. У вас {warnings[member.id]} предупреждений.")
    else:
            await ctx.send("У вас нет разрешения предупреждать пользователей!")

@bot.command()
async def warnings(ctx, member: disnake.Member):
    if ctx.author.guild_permissions.administrator:
        if member.id in warnings:
            await ctx.send(f"{member.mention} для {warnings[member.id]} предупреждения.")
        else:
            await ctx.send(f"{member.mention} не имеет предупреждений.")
    else:
        await ctx.send("У вас нет разрешения предупреждать пользователей!")

@bot.command()
async def resetwarnings(ctx, member: disnake.Member):
    if ctx.author.guild_permissions.administrator:
        if member.id in warnings:
            del warnings[member.id]
            await ctx.send(f"{member.mention}'Предупреждения были сброшены.")
        else:
            await ctx.send(f"{member.mention} не имеет предупреждений о необходимости сброса.")
    else:
        await ctx.send("У вас нет разрешения на сброс предупреждений!")

@bot.command()
async def бот(ctx):
    member = ctx.author # получаем автора сообщения
    embed = disnake.Embed(title="Сообщение доставлено", colour=0xFFFFFF, description="") #Поля не должны быть пустыми.
    await ctx.channel.send(embed=embed)
    await member.send("Все вопросы к создателю бота: <@705384362035773451>")

@bot.event
async def on_ready():
  print('Малышка готова к работе')
  print("Статус: Не беспокоить")
  await bot.change_presence(status=disnake.Status.do_not_disturb, activity=disnake.Game("help"))

@bot.event
async def on_command(ctx):
    log_channel = bot.get_channel(LOG_CHANNEL_ID)
    if log_channel:
        embed = disnake.Embed(
            title="Команда вызвана",
            description="Информация о вызванной команде",
            color=disnake.Color.blue()
        )
        embed.add_field(name="Команда", value=f"`{ctx.command}`", inline=False)
        embed.add_field(name="Автор", value=ctx.author.mention, inline=True)
        embed.add_field(name="Канал", value=ctx.channel.mention, inline=True)
        embed.timestamp = ctx.message.created_at

        await log_channel.send(embed=embed)

@bot.event
async def on_command_error(ctx, error):
    log_channel = bot.get_channel(LOG_CHANNEL_ID)
    if log_channel:
        embed = disnake.Embed(
            title="Ошибка команды",
            description="Произошла ошибка при выполнении команды",
            color=disnake.Color.red()
        )
        embed.add_field(name="Команда", value=f"`{ctx.command}`", inline=False)
        embed.add_field(name="Ошибка", value=str(error), inline=False)
        embed.timestamp = ctx.message.created_at

        await log_channel.send(embed=embed)

@bot.event
async def on_message_delete(message):
    channel = bot.get_channel(1286670342005456926)
    emb = disnake.Embed(
        title='Удаление сообщения 🗑',
        color=0xFFFFFF,
        timestamp=message.created_at
    )
    emb.add_field(name="Пользователь:", value=f"{message.author.mention}", inline=False)
    emb.add_field(name='Канал:', value=f'<#{message.channel.id}>', inline=False)
    emb.add_field(name='Сообщение:', value=f'{message.content}', inline=False)
    emb.add_field(name='ID сообщения:', value=f'`{message.id}`', inline=False)
    emb.set_footer(text='Логи Сообщений | Almazov Famq')

    await channel.send(embed=emb)

@bot.event
async def on_voice_state_update(member, before, after):
    if before.channel == after.channel:
      return
    if not before.channel:
      channel = bot.get_channel(1286670342005456926)
      embed = disnake.Embed(title = f"Пользователь {member.name} зашёл в голосовой канал", description = f"Канал: {after.channel.mention}", color  = member.color)
      return await channel.send(embed = embed)

    if not after.channel:
      channel = bot.get_channel(1286670342005456926)
      embed = disnake.Embed(title = f"Пользователь {member.name} вышел из голосового канала", description = f"Канал: {before.channel.mention}", color  = member.color)
      return await channel.send(embed = embed)
    else:
      channel = bot.get_channel(1286670342005456926)
      embed = disnake.Embed(title = f"Пользователь {member.name} перешёл в голосовой канал", description = f"Канал до: {before.channel.mention}\nКанал после {after.channel.mention}", color  = member.color)
      return await channel.send(embed = embed)

@bot.event
async def on_member_join(member):
    channels = disnake.utils.get(member.guild.channels, name="welcome")
    member_create = f'{disnake.utils.format_dt(member.created_at, "F")} {disnake.utils.format_dt(member.created_at, "R")}'
    embed = disnake.Embed(timestamp=datetime.datetime.now(),
                          description=f":inbox_tray: **Участник присоединился к серверу**\n\n"
                                      f"**Участник**\n{member.mention} | `{member.name}#{member.discriminator}`\n\n"
                                      f"**Дата регистрации**\n{member_create}\n")
    embed.set_thumbnail(url=member.display_avatar.url)
    embed.set_footer(text="Member ID: {}".format(member.id), icon_url=member.display_avatar.url)
    embed.timestamp = datetime.datetime.utcnow()
    await channels.send(embed=embed)

@bot.event
async def on_member_remove(member):
    channels = disnake.utils.get(member.guild.channels, name="welcome")
    member_join = f'{disnake.utils.format_dt(member.joined_at, "F")} {disnake.utils.format_dt(member.joined_at, "R")}'
    embed = disnake.Embed(timestamp=datetime.datetime.now(),
                          description=f":outbox_tray: **Участник покинул сервер**\n\n"
                                      f"**Участник**\n{member.mention} | `{member.name}#{member.discriminator}`\n\n"
                                      f"**Дата входа**\n{member_join}\n")
    embed.set_thumbnail(url=member.display_avatar.url)
    embed.set_footer(text="Member ID: {}".format(member.id), icon_url=member.display_avatar.url)
    embed.timestamp = datetime.datetime.utcnow()
    await channels.send(embed=embed)

@bot.command()
async def help(ctx):
    """Команда help

    Чтобы не писать тысячу строк одинакового кода, лучше занесем название и описание команд в списки,
    и переберм в цикле.

    """

    embed = disnake.Embed(
        title="Help menu",
        description="Команды для участников сервера Помощник машиниста"
    )
    commands_list = ["!бот", "!botik", "!пинг", "!inf", "!user"]
    descriptions_for_commands = ["Информация по созданию бота", "Информация о боте discord", "пинг бота", "Участники с ролью", "информация пользователя"]

    for command_name, description_command in zip(commands_list, descriptions_for_commands):
        embed.add_field(
            name=command_name,
            value=description_command,
            inline=False
        )

    await ctx.send(embed=embed)

@bot.command()
async def ahelp(ctx):
    """Команда ahelp

    """

    embed = disnake.Embed(
        title="Help menu Администратора",
        description="Команды для Администратора discord сервера Помощник машиниста"
    )
    commands_list = ["!kick", '!ban', '!unban', '!mute', '!unmute', '!очистить']
    descriptions_for_commands = ["Кикает пользователя с сервера discord", 'Блокировка пользователя сервера discord', 'Разблокировка пользователя на сервере discord', 'Пользователь получает мут на сервере', 'Снимает мут с пользователя на сервере', 'Очищает чат']
    for command_name, description_command in zip(commands_list, descriptions_for_commands):
        embed.add_field(
            name=command_name,
            value=description_command,
            inline=False
        )

    await ctx.send(embed=embed)

@bot.command(pass_context=True)
@commands.has_permissions(administrator=True)
async def голлосование(ctx, content):
    channel = ctx.channel
    emb = disnake.Embed(title=f'Голосование.', description='Голосуем за ' + str(content),
                                  colour=disnake.Color.yellow())
    message = await ctx.send(embed=emb)
    await message.add_reaction('✅')
    await message.add_reaction('❌')
    global message_id # Если используется класс, то необходимо создать в классе переменную
    message_id = message.id # Сохраняем id сообщения для голосования

@bot.command(pass_context=True)
@commands.has_permissions(administrator=True)
async def рез(ctx):
    channel = ctx.channel
    message = await channel.fetch_message(message_id) # Ищем сообщение
    # Фильтруем реакции, чтобы остались только нужные
    resactions = [reaction for reaction in message.reactions if reaction.emoji in ['✅', '❌']]
    # Превращаем результат голосования в строку (вычитаем 1 из количества, значение по умолчанию)
    result = ''
    for reaction in resactions:
        result += reaction.emoji + ": " + str(reaction.count - 1)
    emb = disnake.Embed(title=f'Результат.', description='Итог голосования: ' + str(result),
                                  colour=disnake.Color.red())
    await ctx.send(embed=emb)
 
@bot.command()
async def мояинфа(ctx, member: disnake.Member=None):
  if member:
    info_user = member
  elif member == None:
    info_user = ctx.author
    server_members = ctx.guild.members 
    data = "\n".join([i.name for i in server_members])
    embed = disnake.Embed(title = f'Участники сервера', description = f"{data}", color=disnake.Color.green())

    await ctx.send(embed = embed)

@bot.command()
async def user(ctx, member: disnake.Member=None):
  if member:
      info_user = member
  elif member == None:
      info_user = ctx.author
  info_embed = disnake.Embed(color=disnake.Color.green())
  info_embed.add_field(name="Member:", value=f"{info_user.mention}", inline=False)
  info_embed.add_field(name="Имя участника", value=f"{info_user}", inline=False)
  info_embed.add_field(name="ID Участника:", value=f"{info_user.id}", inline=False)
  info_embed.add_field(name="Никнейм:", value=f"{info_user.nick}", inline=False)
  info_embed.add_field(name="Joined at:", value=f"{info_user.joined_at}", inline=False)
  roles = " ".join([role.mention for role in info_user.roles if role.name != "@everyone"])
  info_embed.add_field(name="Роли:", value=f"{roles}", inline=False)
  info_embed.set_footer(text="Данек Алмазов")

  await ctx.send(embed=info_embed)

@bot.command()
async def правила(ctx):
    embed = disnake.Embed(
        color = 0xcc6679,
        title = 'Правила',
        description = 
      '''
        1. Любые оскорбления/переход на личность. [Предупреждение]
        2. Любая реклама во всех её проявлениях (сторонних проектов/групп/сайтов/discord-серверов/видео). [Блокировка аккаунта в discord сервере]
        3. Cпам/флуд - множество сообщений на одинаковую тематику. [Предупреждение]
        4. Любой контент 18+ (аватар/баннеры участников сервера). [Блокировка аккаунта в discord сервере]
        5. Выяснение личных отношений во всех текстовых/голосовых каналах сервера. [Предупреждение]
        6. Введение участников сервера в заблуждение. [Предупреждение | блокировка аккаунта в discord сервере]
        7. Использование оскорбительных никнеймов. [Предупреждение]
        8. Излишнее упоминание администрации в различных каналах discord. [Предупреждение]
        9. Общение в каналах не предназначенных для того. [Предупреждение]
        10. Использование в сообщениях/реакциях неадекватных/оскорбляющих кого-либо эмодзи. [Предупреждение]
        11. Оскорбление или завуалированное оскорбление/упоминание родных. [Предупреждение | блокировка аккаунта в discord сервере]
        12. Запрещено оскорблять нацию/религию/расу человека. [Блокировка аккаунта в discord сервере]
        13. Запрещена продажа сторонних ресурсов, в том числе и аккаунты NEXTRP. [Постоянная блокировка аккаунта в discord сервере]
        14. Инсайды обновлений до их релиза. [Постоянная блокировка аккаунта в discord сервере]
        
        15. Неконструктивная критика. [Предупреждение | блокировка аккаунта в discord сервере сроком на 30 дней]
        16. Нет, мы не против критики! Если вам что-либо не нравится в игре, есть негативный опыт в чем-либо или хотите оставить пожелания по улучшению - мы только ЗА! Но давайте постараемся правильно преподносить информацию и уважать друг друга! 
        17. Запрещены попытки разжигания и фактическое разжигание различных конфликтов, навязчивое и грубое поведение, создание токсической атмосферы. [Предупреждение]
        18. Запрещена рассылка нацистских фотографий/видео, рассылка порнографии, расчлененки и т.д. [Постоянная блокировка аккаунта в discord сервере]
        19. Распространение личной информации (Фото, видео, ссылки на соц. сети, телефонные номера, адрес проживания, фотошоп лиц людей). [Постоянная блокировка].
        20. Систематические нарушения правил на нашем сервере. [Блокировка аккаунта сроком на 30 дней]
        21. Обход блокировки. [Блокировка на срок выданный ранее]
        ''',
        )
    await ctx.send( embed = embed )

@bot.command()
async def др(ctx):
      embed = disnake.Embed(
          color = 0xcc6666,
          title = 'Поздравление от ДПС МСК',
          description = 
        '''
        ***Всех приветствую!
        Сегодня свой День Рождения празнует а именно:
         - <@705384362035773451>
        Давайте его поздавим.
        ***
          ''',
          )
      await ctx.send( embed = embed )


@bot.command()
async def inf(ctx, role: disnake.Role):
    data = "\n".join([(member.name or member.nick) for member in role.members])
    embed=disnake.Embed(title=f"Участники с ролью {role}\n", description=f"{data}\n")
    await ctx.send(embed=embed)

@bot.command(pass_context=True)
async def report(ctx, *, arg):
    emb = disnake.Embed(title="REPORT", description=f"От пользователя {ctx.author.mention}", colour=disnake.Color.red())
    emb.add_field(name="Причина:", value=arg, inline=True)
    # Получаем все каналы в нашей гильдии.
    for channel in ctx.guild.channels:
        if channel.name == "report":
            # Объект канала, который мы будем использовать для отправки сообщения.
            channel = bot.get_channel(channel.id)
            # Отправляем сообщение в нужный нам канал.
            await channel.send(embed=emb)

@bot.event
async def on_member_update(before, after):
    if before.roles != after.roles:
        channel = bot.get_channel(1272479618112426037)
        emb = disnake.Embed(description = f'**Обновление ролей пользователя -  {before.mention}**', colour = disnake.Color.red())
        emb.add_field(name = '**Роли до**', value = ", ".join([r.mention for r in before.roles])) 
        emb.add_field(name = '**Роли после**', value = ", ".join([r.mention for r in after.roles])) 
        async for event in before.guild.audit_logs(limit=1, action=disnake.AuditLogAction.member_role_update): # https://discordpy.readthedocs.io/en/v1.3.4/api.html#discord.AuditLogAction.member_role_update
            # event: AuditLogEntry — https://discordpy.readthedocs.io/en/v1.3.4/api.html#discord.AuditLogEntry
            if getattr(event.target, "id", None) != before.id:
                # изменение ролей пользователя прошло без записи в логах аудита, или в лог аудита попала другая запись перед выполнением текущего участка кода
                continue
            emb.add_field(name="Изменённые роли", value = ", ".join([getattr(r, "mention", r.id) for r in event.before.roles or event.after.roles]))  # event.before, event.after: AuditLogDiff — https://discordpy.readthedocs.io/en/v1.3.4/api.html#discord.AuditLogDiff 
            emb.add_field(name="Модератор", value = event.user)
            break
        await channel.send(embed = emb)
@bot.command()
async def пинг(ctx):
    embed = disnake.Embed(title="Pong!", description=f"Your ping is {round(bot.latency * 1000)}ms", color=0x00FF00)
    await ctx.send(embed=embed)

@bot.command()
async def botik(ctx):
    embed = disnake.Embed(title="ℹ️ Информация о боте", description="Вот интересная информация о боте!", color=disnake.Color.purple())
    embed.add_field(name="Имя бота", value=bot.user.name, inline=True)
    embed.add_field(name="ID бота", value=bot.user.id, inline=True)
    embed.set_footer(text="Используйте команду !help.")
    await ctx.send(embed=embed)

bot.run("TOKEN")
